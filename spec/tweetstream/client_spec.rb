require 'spec_helper'

describe TweetStream::Client do
  before(:each) do
    TweetStream.configure do |config|
      config.consumer_key = 'abc'
      config.consumer_secret = 'def'
      config.oauth_token = '123'
      config.oauth_token_secret = '456'
    end
    @client = TweetStream::Client.new
  end

  describe '#build_uri' do
    it 'should return a URI' do
      @client.send(:build_uri, '').should be_kind_of(URI)
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
      @stream = stub("EM::Twitter::Client",
        :connect => true,
        :unbind => true,
        :each => true,
        :on_error => true,
        :on_max_reconnects => true,
        :on_reconnect => true,
        :connection_completed => true,
        :on_no_data_received => true
      )
      EM.stub!(:run).and_yield
      EM::Twitter::Client.stub!(:connect).and_return(@stream)
    end

    it 'should try to connect via a JSON stream with basic auth' do
      EM::Twitter::Client.should_receive(:connect).with(
        :path => URI.parse('/1/statuses/filter.json'),
        :method => 'POST',
        :user_agent => TweetStream::Configuration::DEFAULT_USER_AGENT,
        :on_inited => nil,
        :params => { :track => 'monday'},
        :oauth => {
          :consumer_key => 'abc',
          :consumer_secret => 'def',
          :token => '123',
          :token_secret => '456'
        }
      ).and_return(@stream)

      @client.track('monday')
    end

    describe '#each' do
      it 'should call the appropriate parser' do
        @client = TweetStream::Client.new
        MultiJson.should_receive(:decode).and_return({})
        @stream.should_receive(:each).and_yield(sample_tweets[0].to_json)
        @client.track('abc','def')
      end

      it 'should yield a Twitter::Status' do
        @stream.should_receive(:each).and_yield(sample_tweets[0].to_json)
        @client.track('abc'){|s| s.should be_kind_of(Twitter::Status)}
      end

      it 'should also yield the client if a block with arity 2 is given' do
        @stream.should_receive(:each).and_yield(sample_tweets[0].to_json)
        @client.track('abc'){|s,c| c.should == @client}
      end

      it 'should include the proper values' do
        tweet = sample_tweets[0]
        tweet[:id] = 123
        tweet[:user][:screen_name] = 'monkey'
        tweet[:text] = "Oo oo aa aa"
        @stream.should_receive(:each).and_yield(tweet.to_json)
        @client.track('abc') do |s|
          s[:id].should == 123
          s.user.screen_name.should == 'monkey'
          s.text.should == 'Oo oo aa aa'
        end
      end

      it 'should call the on_scrub_geo if specified' do
        scrub_geo = '{ "scrub_geo": { "user_id": 1234, "user_id_str": "1234", "up_to_status_id":9876, "up_to_status_id_string": "9876" } }'
        @stream.should_receive(:each).and_yield(scrub_geo)
        @client.on_scrub_geo do |up_to_status_id, user_id|
          up_to_status_id.should == 9876
          user_id.should == 1234
        end.track('abc')
      end

      it 'should call the delete if specified' do
        delete = '{ "delete": { "status": { "id": 1234, "user_id": 3 } } }'
        @stream.should_receive(:each).and_yield(delete)
        @client.on_delete do |id, user_id|
          id.should == 1234
          user_id.should == 3
        end.track('abc')
      end

      it 'should call the on_limit if specified' do
        limit = '{ "limit": { "track": 1234 } }'
        @stream.should_receive(:each).and_yield(limit)
        @client.on_limit do |track|
          track.should == 1234
        end.track('abc')
      end

      context "using on_anything" do
        it "yields the raw hash" do
          hash = {:id => 1234}
          @stream.should_receive(:each).and_yield(hash.to_json)
          yielded_hash = nil
          @client.on_anything do |hash|
            yielded_hash = hash
          end.track('abc')
          yielded_hash.should_not be_nil
          yielded_hash[:id].should == 1234
        end
        it 'yields itself if block has an arity of 2' do
          hash = {:id => 1234}
          @stream.should_receive(:each).and_yield(hash.to_json)
          yielded_client = nil
          @client.on_anything do |_, client|
            yielded_client = client
          end.track('abc')
          yielded_client.should_not be_nil
          yielded_client.should == @client
        end
      end

      context 'using on_timeline_status' do
        it 'yields a Status' do
          tweet = sample_tweets[0]
          tweet[:id] = 123
          tweet[:user][:screen_name] = 'monkey'
          tweet[:text] = "Oo oo aa aa"
          @stream.should_receive(:each).and_yield(tweet.to_json)
          yielded_status = nil
          @client.on_timeline_status do |status|
            yielded_status = status
          end.track('abc')
          yielded_status.should_not be_nil
          yielded_status[:id].should == 123
          yielded_status.user.screen_name.should == 'monkey'
          yielded_status.text.should == 'Oo oo aa aa'
        end
        it 'yields itself if block has an arity of 2' do
          @stream.should_receive(:each).and_yield(sample_tweets[0].to_json)
          yielded_client = nil
          @client.on_timeline_status do |_, client|
            yielded_client = client
          end.track('abc')
          yielded_client.should_not be_nil
          yielded_client.should == @client
        end
      end

      context 'using on_direct_message' do
        it 'yields a DirectMessage' do
          direct_message = sample_direct_messages[0]
          direct_message["direct_message"]["id"] = 1234
          direct_message["direct_message"]["sender"]["screen_name"] = "coder"
          @stream.should_receive(:each).and_yield(direct_message.to_json)
          yielded_dm = nil
          @client.on_direct_message do |dm|
            yielded_dm = dm
          end.userstream
          yielded_dm.should_not be_nil
          yielded_dm.id.should == 1234
          yielded_dm.sender.screen_name.should == "coder"
        end

        it 'yields itself if block has an arity of 2' do
          @stream.should_receive(:each).and_yield(sample_direct_messages[0].to_json)
          yielded_client = nil
          @client.on_direct_message do |_, client|
            yielded_client = client
          end.userstream
          yielded_client.should == @client
        end
      end

      it 'should call on_error if a non-hash response is received' do
        @stream.should_receive(:each).and_yield('["favorited"]')
        @client.on_error do |message|
          message.should == 'Unexpected JSON object in stream: ["favorited"]'
        end.track('abc')
      end

      it 'should call on_error if a json parse error occurs' do
        @stream.should_receive(:each).and_yield("{'a_key':}")
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

  describe 'API methods' do
    %w(firehose retweet sample links).each do |method|
      it "##{method} should make a call to start with \"statuses/#{method}\"" do
        @client.should_receive(:start).once.with('statuses/' + method, {})
        @client.send(method)
      end
    end

    describe '#filter' do
      it 'makes a call to "statuses/filter" with the query params provided' do
        @client.should_receive(:start).once.with('statuses/filter', :follow => 123, :method => :post)
        @client.filter(:follow => 123)
      end
      it 'makes a call to "statuses/filter" with the query params provided longitude/latitude pairs, separated by commas ' do
        @client.should_receive(:start).once.with('statuses/filter', :locations => '-122.75,36.8,-121.75,37.8,-74,40,-73,41', :method => :post)
        @client.filter(:locations => '-122.75,36.8,-121.75,37.8,-74,40,-73,41')
      end
    end

    describe '#follow' do
      it 'makes a call to start with "statuses/filter" and a follow query parameter' do
        @client.should_receive(:start).once.with('statuses/filter', :follow => [123], :method => :post)
        @client.follow(123)
      end

      it 'comma-joins multiple arguments' do
        @client.should_receive(:start).once.with('statuses/filter', :follow => [123,456], :method => :post)
        @client.follow(123, 456)
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

    describe '#track' do
      it 'makes a call to start with "statuses/filter" and a track query parameter' do
        @client.should_receive(:start).once.with('statuses/filter', :track => ['test'], :method => :post)
        @client.track('test')
      end

      it 'comma-joins multiple arguments' do
        @client.should_receive(:start).once.with('statuses/filter', :track => ['foo', 'bar', 'baz'], :method => :post)
        @client.track('foo', 'bar', 'baz')
      end

      it 'comma-joins an array of arguments' do
        @client.should_receive(:start).once.with('statuses/filter', :track => [['foo','bar','baz']], :method => :post)
        @client.track(['foo','bar','baz'])
      end

      it 'should call #start with "statuses/filter" and the provided queries' do
        @client.should_receive(:start).once.with('statuses/filter', :track => ['rock'], :method => :post)
        @client.track('rock')
      end
    end
  end

  %w(on_delete on_limit on_inited on_reconnect on_no_data_received).each do |proc_setter|
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

  describe '#stop' do
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

  describe '#close_connection' do
    it 'should not call EventMachine::stop_event_loop' do
      EventMachine.should_not_receive :stop_event_loop
      TweetStream::Client.new.close_connection.should be_nil
    end
  end

  describe '#stop_stream' do
    before(:each) do
      @stream = stub("EM::Twitter::Client",
        :connect => true,
        :unbind => true,
        :each => true,
        :on_error => true,
        :on_max_reconnects => true,
        :on_reconnect => true,
        :connection_completed => true,
        :on_no_data_received => true,
        :stop => true
      )
      EM::Twitter::Client.stub!(:connect).and_return(@stream)
      @client = TweetStream::Client.new
      @client.connect('/')
    end

    it "should call stream.stop to cleanly stop the current stream" do
      @stream.should_receive(:stop)
      @client.stop_stream
    end

    it 'should not stop eventmachine' do
      EventMachine.should_not_receive :stop_event_loop
      @client.stop_stream
    end
  end

  describe "basic auth" do
    before do
      TweetStream.configure do |config|
        config.username = 'tweetstream'
        config.password = 'rubygem'
        config.auth_method = :basic
      end
      @client = TweetStream::Client.new

      @stream = stub("EM::Twitter::Client",
        :connect => true,
        :unbind => true,
        :each => true,
        :on_error => true,
        :on_max_reconnects => true,
        :on_reconnect => true,
        :connection_completed => true,
        :on_no_data_received => true
      )
      EM.stub!(:run).and_yield
      EM::Twitter::Client.stub!(:connect).and_return(@stream)
    end

    it 'should try to connect via a JSON stream with oauth' do
      EM::Twitter::Client.should_receive(:connect).with(
        :path => URI.parse('/1/statuses/filter.json'),
        :method => 'POST',
        :user_agent => TweetStream::Configuration::DEFAULT_USER_AGENT,
        :on_inited => nil,
        :params => {:track => 'monday'},
        :basic => {
          :username => 'tweetstream',
          :password => 'rubygem'
        }
      ).and_return(@stream)

      @client.track('monday')
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

        @stream = stub("EM::Twitter::Client",
          :connect => true,
          :unbind => true,
          :each => true,
          :on_error => true,
          :on_max_reconnects => true,
          :on_reconnect => true,
          :connection_completed => true,
          :on_no_data_received => true
        )
        EM.stub!(:run).and_yield
        EM::Twitter::Client.stub!(:connect).and_return(@stream)
      end

      it 'should try to connect via a JSON stream with oauth' do
        EM::Twitter::Client.should_receive(:connect).with(
          :path => URI.parse('/1/statuses/filter.json'),
          :method => 'POST',
          :user_agent => TweetStream::Configuration::DEFAULT_USER_AGENT,
          :on_inited => nil,
          :params => {:track => 'monday'},
          :oauth => {
            :consumer_key => '123456789',
            :consumer_secret => 'abcdefghijklmnopqrstuvwxyz',
            :token => '123456789',
            :token_secret => 'abcdefghijklmnopqrstuvwxyz'
          }
        ).and_return(@stream)

        @client.track('monday')
      end

      context "when calling #userstream" do
        it "sends the userstream host" do
          EM::Twitter::Client.should_receive(:connect).with(hash_including(:host => "userstream.twitter.com")).and_return(@stream)
          @client.userstream
        end

        it "uses the userstream uri" do
          EM::Twitter::Client.should_receive(:connect).with(hash_including(:path => "/2/user.json")).and_return(@stream)
          @client.userstream
        end
      end

      context "when calling #sitestream" do
        it "sends the sitestream host" do
          EM::Twitter::Client.should_receive(:connect).with(hash_including(:host => "sitestream.twitter.com")).and_return(@stream)
          @client.sitestream
        end

        it "uses the userstream uri" do
          EM::Twitter::Client.should_receive(:connect).with(hash_including(:path => "/2b/site.json")).and_return(@stream)
          @client.sitestream
        end

        it 'supports the "with followings"' do
          @client.should_receive(:start).once.with('', hash_including(:with => 'followings')).and_return(@stream)
          @client.sitestream(['115192457'], :followings => true)
        end

        context 'control management' do
          before do
            @control_response = {"control" =>
              {
                "control_uri" =>"/2b/site/c/01_225167_334389048B872A533002B34D73F8C29FD09EFC50"
              }
            }
          end
          it 'assigns the control_uri' do
            @stream.should_receive(:each).and_yield(@control_response.to_json)
            @client.sitestream

            @client.control_uri.should eq("/2b/site/c/01_225167_334389048B872A533002B34D73F8C29FD09EFC50")
          end

          it 'instantiates a SiteStreamClient' do
            @stream.should_receive(:each).and_yield(@control_response.to_json)
            @client.sitestream

            @client.control.should be_kind_of(TweetStream::SiteStreamClient)
          end

          it "passes the client's on_error to the SiteStreamClient" do
            called = false
            @client.on_error { |err| called = true }
            @stream.should_receive(:each).and_yield(@control_response.to_json)
            @client.sitestream

            @client.control.on_error.call

            called.should be_true
          end
        end

        context 'data handling' do
          before do
            tweet = sample_tweets[0]
            @ss_message = {'for_user' => '12345', 'message' => {'id' => 123, 'user' => {'screen_name' => 'monkey'}, 'text' => 'Oo oo aa aa'}}
          end

          it 'yields a site stream message' do
            @stream.should_receive(:each).and_yield(@ss_message.to_json)
            yielded_status = nil
            @client.sitestream do |message|
              yielded_status = message
            end
            yielded_status.should_not be_nil
            yielded_status[:for_user].should == '12345'
            yielded_status[:message][:user][:screen_name].should == 'monkey'
            yielded_status[:message][:text].should == 'Oo oo aa aa'
          end
          it 'yields itself if block has an arity of 2' do
            @stream.should_receive(:each).and_yield(@ss_message.to_json)
            yielded_client = nil
            @client.sitestream do |_, client|
              yielded_client = client
            end
            yielded_client.should_not be_nil
            yielded_client.should == @client
          end
        end
      end
    end
  end

end
