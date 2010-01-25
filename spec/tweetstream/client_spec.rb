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
      @stream = stub("Twitter::JSONStream", 
        :connect => true,
        :unbind => true, 
        :each_item => true, 
        :on_error => true,
        :on_max_reconnects => true,
        :connection_completed => true
      )
      EM.stub!(:run).and_yield
      Twitter::JSONStream.stub!(:connect).and_return(@stream)
      @client = TweetStream::Client.new('abc','def')
    end
    
    it 'should try to connect via a JSON stream' do
      Twitter::JSONStream.should_receive(:connect).with(
        :auth => 'abc:def',
        :content => 'track=monday',
        :path => URI.parse('/1/statuses/filter.json'),
        :method => 'POST',
        :user_agent => 'TweetStream'
      ).and_return(@stream)
      
      @client.track('monday')
    end
    
    describe '#each_item' do
      it 'should call the appropriate parser' do
        @client = TweetStream::Client.new('abc','def',:active_support)
        TweetStream::Parsers::ActiveSupport.should_receive(:decode).and_return({})
        @stream.should_receive(:each_item).and_yield(sample_tweets[0].to_json)
        @client.track('abc','def')
      end
      
      it 'should yield a TweetStream::Status' do
        @stream.should_receive(:each_item).and_yield(sample_tweets[0].to_json)
        @client.track('abc'){|s| s.should be_kind_of(TweetStream::Status)}
      end
      
      it 'should also yield the client if a block with arity 2 is given' do
        @stream.should_receive(:each_item).and_yield(sample_tweets[0].to_json)
        @client.track('abc'){|s,c| c.should == @client}
      end
      
      it 'should include the proper values' do
        tweet = sample_tweets[0]
        tweet[:id] = 123
        tweet[:user][:screen_name] = 'monkey'
        tweet[:text] = "Oo oo aa aa"
        @stream.should_receive(:each_item).and_yield(tweet.to_json)
        @client.track('abc') do |s| 
          s[:id].should == 123
          s.user.screen_name.should == 'monkey'
          s.text.should == 'Oo oo aa aa'
        end
      end
      
      it 'should call the on_delete if specified' do
        delete = '{ "delete": { "status": { "id": 1234, "user_id": 3 } } }'
        @stream.should_receive(:each_item).and_yield(delete)
        @client.on_delete do |id, user_id| 
          id.should == 1234
          user_id.should == 3
        end.track('abc')
      end
      
      it 'should call the on_limit if specified' do
        limit = '{ "limit": { "track": 1234 } }'
        @stream.should_receive(:each_item).and_yield(limit)
        @client.on_limit do |track|
          track.should == 1234
        end.track('abc')
      end
    end
    
    describe '#on_error' do
      it 'should pass the message on to the error block' do
        @stream.should_receive(:on_error).and_yield('Uh oh')
        @client.on_error do |m|
          m.should == 'Uh oh'
        end.track('abc')
      end
    end
    
    describe '#on_max_reconnects' do
      it 'should raise a ReconnectError' do
        @stream.should_receive(:on_max_reconnects).and_yield(30, 20)
        lambda{@client.track('abc')}.should raise_error(TweetStream::ReconnectError) do |e|
          e.timeout.should == 30
          e.retries.should == 20
        end
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

  describe 'instance .stop' do
    it 'should call EventMachine::stop_event_loop' do
      EventMachine.should_receive :stop_event_loop
      TweetStream::Client.new('test','fake').stop.should be_nil
    end
    
    it 'should return the last status yielded' do
      EventMachine.should_receive :stop_event_loop
      client = TweetStream::Client.new('test','fake')
      client.send(:instance_variable_set, :@last_status, {})
      client.stop.should == {}
    end
  end
end
