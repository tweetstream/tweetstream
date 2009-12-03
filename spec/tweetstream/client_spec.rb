require File.dirname(__FILE__) + '/../spec_helper'

describe TweetStream::Client do
  it 'should set the username and password from the initializers' do
    @client = TweetStream::Client.new('abc','def')
    @client.username.should == 'abc'
    @client.password.should == 'def'
  end

  describe '#build_uri' do
    before do
      @client = TweetStream::Client.new('abc','def')
    end

    it 'should return a URI' do
      @client.send(:build_uri, '').is_a?(URI).should be_true
    end

    it 'should contain the auth information from the client' do
      @client.send(:build_uri, '').user.should == 'abc'
      @client.send(:build_uri, '').password.should == 'def'
    end

    it 'should have the specified path with the version prefix and a json extension' do
      @client.send(:build_uri, 'awesome').path.should == '/1/awesome.json'
    end

    it 'should add on a query string if such parameters are specified' do
      @client.send(:build_uri, 'awesome', :q => 'abc').query.should == 'q=abc'
    end
  end

  describe '#build_post_body' do
    before do
      @client = TweetStream::Client.new('abc','def')
    end
  
    it 'should return a blank string if passed a nil value' do
      @client.send(:build_post_body, nil).should == ''
    end

    it 'should return a blank string if passed an empty hash' do
      @client.send(:build_post_body, {}).should == ''
    end

    it 'should add a query parameter for a key' do
      @client.send(:build_post_body, {:query => 'abc'}).should == 'query=abc'
    end

    it 'should escape characters in the value' do
      @client.send(:build_post_body, {:query => 'awesome guy'}).should == 'query=awesome+guy'
    end

    it 'should join multiple pairs together' do
      ['a=b&c=d','c=d&a=b'].include?(@client.send(:build_post_body, {:a => 'b', :c => 'd'})).should be_true
    end
  end

  describe '#start' do
    before do
      @client = TweetStream::Client.new('abc','def')
    end

    it 'should make a call to Yajl::HttpStream' do
      Yajl::HttpStream.should_receive(:new).and_return(y = mock("Yajl::HttpStream"))
      y.should_receive(:get).once.with(URI.parse('http://abc:def@stream.twitter.com/1/cool.json'), :symbolize_keys => true).and_return({})
      @client.start('cool')
    end

    it 'should yield a TwitterStream::Status for each update' do
      Yajl::HttpStream.should_receive(:new).and_return(y = mock("Yajl::HttpStream"))
      y.should_receive(:post).once.with(URI.parse('http://abc:def@stream.twitter.com/1/statuses/filter.json'), 'track=musicmonday', :symbolize_keys => true).and_yield(sample_tweets[0])
      @client.track('musicmonday') do |status|
        status.is_a?(TweetStream::Status).should be_true
        @yielded = true
      end
      @yielded.should be_true
    end
    
    it 'should wrap Yajl errors in TweetStream errors' do
      Yajl::HttpStream.should_receive(:new).and_return(y = mock("Yajl::HttpStream"))
      y.should_receive(:get).once.with(URI.parse('http://abc:def@stream.twitter.com/1/cool.json'), :symbolize_keys => true).and_raise(Yajl::HttpStream::InvalidContentType)
      lambda{@client.start('cool')}.should raise_error(TweetStream::ConnectionError)
    end
    
    {
      :delete => {:delete => {:status => {:id => 1234, :user_id => 3}}},
      :limit => {:limit => {:track => 1234}}
    }.each_pair do |special_method, special_object|
      it "should make a call to the #{special_method} proc if a #{special_method} object is given" do
        @called = false
        @proc = Proc.new{|*args| @called = true }
        @client.send("on_#{special_method}", &@proc)
        Yajl::HttpStream.should_receive(:new).and_return(y = mock("Yajl::HttpStream"))
        y.should_receive(:post).once.with(URI.parse('http://abc:def@stream.twitter.com/1/statuses/filter.json'), "track=musicmonday", :symbolize_keys => true).and_yield(special_object)
        @client.track('musicmonday')
        @called.should == true
      end
      
      it "should accept a proc on a :#{special_method} option if a #{special_method} object is given" do
        @called = false
        @proc = Proc.new{|*args| @called = true }
        Yajl::HttpStream.should_receive(:new).and_return(y = mock("Yajl::HttpStream"))
        y.should_receive(:post).once.with(URI.parse('http://abc:def@stream.twitter.com/1/statuses/filter.json'), "track=musicmonday", :symbolize_keys => true).and_yield(special_object)
        @client.track('musicmonday', special_method => @proc)
        @called.should == true
      end
    end
  end
  
  describe ' API methods' do
    before do
      @client = TweetStream::Client.new('abc','def')
    end
    
    %w(firehose retweet sample).each do |method|
      it "##{method} should make a call to start with \"statuses/#{method}\"" do
        @client.should_receive(:start).once.with('statuses/' + method, {})
        @client.send(method)
      end
    end
    
    it '#track should make a call to start with "statuses/filter" and a track query parameter' do
      @client.should_receive(:start).once.with('statuses/filter', :track => 'test', :method => :post)
      @client.track('test')
    end
    
    it '#track should comma-join multiple arguments' do
      @client.should_receive(:start).once.with('statuses/filter', :track => 'foo,bar,baz', :method => :post)
      @client.track('foo', 'bar', 'baz')
    end
    
    it '#follow should make a call to start with "statuses/filter" and a follow query parameter' do
      @client.should_receive(:start).once.with('statuses/filter', :follow => '123', :method => :post)
      @client.follow(123)
    end
    
    it '#follow should comma-join multiple arguments' do
      @client.should_receive(:start).once.with('statuses/filter', :follow => '123,456', :method => :post)
      @client.follow(123, 456)
    end
    
    it '#filter should make a call to "statuses/filter" with the query params provided' do
      @client.should_receive(:start).once.with('statuses/filter', :follow => '123', :method => :post)
      @client.filter(:follow => 123)
    end
  end
  
  %w(on_delete on_limit).each do |proc_setter|
    describe "##{proc_setter}" do
      before do
        @client = TweetStream::Client.new('abc','def')
      end
      
      it 'should set when a block is given' do
        proc = Proc.new{|a,b| puts a }
        @client.send(proc_setter, &proc)
        @client.send(proc_setter).should == proc
      end
    end
  end

  describe '#track' do
    before do
      @client = TweetStream::Client.new('abc','def')
    end

    it 'should call #start with "statuses/filter" and the provided queries' do
      @client.should_receive(:start).once.with('statuses/filter', :track => 'rock', :method => :post)
      @client.track('rock')
    end
  end
  
  describe '.stop' do
    it 'should raise a TweetStream::Terminated error' do
      lambda{ TweetStream::Client.stop }.should raise_error(TweetStream::Terminated)
    end
    
    it 'should not cause a TweetStream to crash with a real exception' do
      @client = TweetStream::Client.new('abc','def')
      @statuses = []
      Yajl::HttpStream.should_receive(:new).and_return(y = mock("Yajl::HttpStream"))
      y.should_receive(:post).once.with(URI.parse('http://abc:def@stream.twitter.com/1/statuses/filter.json'), 'track=musicmonday', :symbolize_keys => true).and_yield(sample_tweets[0])
      @client.track('musicmonday') do |status|
        @statuses << status
        TweetStream::Client.stop
      end.should == @statuses.first
      @statuses.size.should == 1
    end
  end

  describe 'instance .stop' do
    it 'should stop to receive the stream' do
      @client = TweetStream::Client.new('abc','def')
      Yajl::HttpStream.should_receive(:new).and_return(y = mock('Yajl::HttpStream'))
      y.should_receive(:post)
      y.should_receive(:terminate).once

      @client.follow('10')
      @client.stop
    end
  end
end
