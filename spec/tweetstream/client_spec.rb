require File.dirname(__FILE__) + '/../spec_helper'

describe TweetStream::Client do
  before(:each) do
    TweetStream.configure do |config|
      config.username = 'abc'
      config.password = 'def'
      config.auth_method = :basic
    end
    @client = TweetStream::Client.new
  end

  describe '#build_uri' do
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
    end

    it 'should try to connect via a JSON stream with basic auth' do
      Twitter::JSONStream.should_receive(:connect).with(
        :path => URI.parse('/1/statuses/filter.json'),
        :method => 'POST',
        :user_agent => TweetStream::Configuration::DEFAULT_USER_AGENT,
        :on_inited => nil,
        :filters => 'monday',
        :params => {},
        :ssl => true,
        :auth => 'abc:def'
      ).and_return(@stream)

      @client.track('monday')
    end

    describe '#each_item' do
      it 'should call the appropriate parser' do
        @client = TweetStream::Client.new
        MultiJson.should_receive(:decode).and_return({})
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

      it 'should call on_error if a non-hash response is received' do
        @stream.should_receive(:each_item).and_yield('["favorited"]')
        @client.on_error do |message|
          message.should == 'Unexpected JSON object in stream: ["favorited"]'
        end.track('abc')
      end

      it 'should call on_error if a json parse error occurs' do
        @stream.should_receive(:each_item).and_yield("{'a_key':}")
        @client.on_error do |message|
          message.should == "MultiJson::DecodeError occured in stream: {'a_key':}"
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

      it 'should return the block when defined' do
        @client.on_error do |m|
          puts 'ohai'
        end
        @client.on_error.should be_kind_of(Proc)
      end

      it 'should return nil when undefined' do
        @client.on_error.should be_nil
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
    %w(firehose retweet sample).each do |method|
      it "##{method} should make a call to start with \"statuses/#{method}\"" do
        @client.should_receive(:start).once.with('statuses/' + method, {})
        @client.send(method)
      end
    end

    it '#track should make a call to start with "statuses/filter" and a track query parameter' do
      @client.should_receive(:start).once.with('statuses/filter', :track => ['test'], :method => :post)
      @client.track('test')
    end

    it '#track should comma-join multiple arguments' do
      @client.should_receive(:start).once.with('statuses/filter', :track => ['foo', 'bar', 'baz'], :method => :post)
      @client.track('foo', 'bar', 'baz')
    end

    it '#track should comma-join an array of arguments' do
      @client.should_receive(:start).once.with('statuses/filter', :track => [['foo','bar','baz']], :method => :post)
      @client.track(['foo','bar','baz'])
    end

    it '#follow should make a call to start with "statuses/filter" and a follow query parameter' do
      @client.should_receive(:start).once.with('statuses/filter', :follow => [123], :method => :post)
      @client.follow(123)
    end

    it '#follow should comma-join multiple arguments' do
      @client.should_receive(:start).once.with('statuses/filter', :follow => [123,456], :method => :post)
      @client.follow(123, 456)
    end

    it '#filter should make a call to "statuses/filter" with the query params provided' do
      @client.should_receive(:start).once.with('statuses/filter', :follow => 123, :method => :post)
      @client.filter(:follow => 123)
    end
    it '#filter should make a call to "statuses/filter" with the query params provided longitude/latitude pairs, separated by commas ' do
      @client.should_receive(:start).once.with('statuses/filter', :locations => '-122.75,36.8,-121.75,37.8,-74,40,-73,41', :method => :post)
      @client.filter(:locations => '-122.75,36.8,-121.75,37.8,-74,40,-73,41')
    end
  end

  %w(on_delete on_limit on_inited).each do |proc_setter|
    describe "##{proc_setter}" do
      it 'should set when a block is given' do
        proc = Proc.new{|a,b| puts a }
        @client.send(proc_setter, &proc)
        @client.send(proc_setter).should == proc
      end

      it 'should return nil when undefined' do
        @client.send(proc_setter).should be_nil
      end
    end
  end

  describe '#track' do
    it 'should call #start with "statuses/filter" and the provided queries' do
      @client.should_receive(:start).once.with('statuses/filter', :track => ['rock'], :method => :post)
      @client.track('rock')
    end
  end

  describe '#locations' do
    it 'should call #start with "statuses/filter" with the query params provided longitude/latitude pairs' do
      @client.should_receive(:start).once.with('statuses/filter', :locations => ['-122.75,36.8,-121.75,37.8,-74,40,-73,41'], :method => :post)
      @client.locations('-122.75,36.8,-121.75,37.8,-74,40,-73,41')
    end

    it 'should call #start with "statuses/filter" with the query params provided longitude/latitude pairs and additional filter' do
      @client.should_receive(:start).once.with('statuses/filter', :locations => ['-122.75,36.8,-121.75,37.8,-74,40,-73,41'], :track => 'rock', :method => :post)
      @client.locations('-122.75,36.8,-121.75,37.8,-74,40,-73,41', :track => 'rock')
    end
  end

  describe 'instance .stop' do
    it 'should call EventMachine::stop_event_loop' do
      EventMachine.should_receive :stop_event_loop
      TweetStream::Client.new.stop.should be_nil
    end

    it 'should return the last status yielded' do
      EventMachine.should_receive :stop_event_loop
      client = TweetStream::Client.new
      client.send(:instance_variable_set, :@last_status, {})
      client.stop.should == {}
    end
  end

  describe "oauth" do
    describe '#start' do
      before do
        TweetStream.configure do |config|
          config.consumer_key = '123456789'
          config.consumer_secret = 'abcdefghijklmnopqrstuvwxyz'
          config.oauth_token = '123456789'
          config.oauth_token_secret = 'abcdefghijklmnopqrstuvwxyz'
          config.auth_method = :oauth
        end
        @client = TweetStream::Client.new

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
      end

      it 'should try to connect via a JSON stream with oauth' do
        Twitter::JSONStream.should_receive(:connect).with(
          :path => URI.parse('/1/statuses/filter.json'),
          :method => 'POST',
          :user_agent => TweetStream::Configuration::DEFAULT_USER_AGENT,
          :on_inited => nil,
          :filters => 'monday',
          :params => {},
          :ssl => true,
          :oauth => {
            :consumer_key => '123456789',
            :consumer_secret => 'abcdefghijklmnopqrstuvwxyz',
            :access_key => '123456789',
            :access_secret => 'abcdefghijklmnopqrstuvwxyz'
          }
        ).and_return(@stream)

        @client.track('monday')
      end
    end
  end

end
