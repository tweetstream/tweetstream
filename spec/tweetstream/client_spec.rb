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
    it 'should call EventMachine::stop_event_loop' do
      EventMachine.should_receive :stop_event_loop
      TweetStream::Client.stop
    end
  end

  describe 'instance .stop' do
    it 'should call EventMachine::stop_event_loop' do
      EventMachine.should_receive :stop_event_loop
      TweetStream::Client.new('test','fake').stop
    end
  end
end
