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
        :on_no_data_received => true,
        :on_unauthorized => true,
        :on_enhance_your_calm => true
      )
      EM.stub!(:run).and_yield
      EM::Twitter::Client.stub!(:connect).and_return(@stream)
    end

    it 'connects if the reactor is already running' do
      EM.stub!(:reactor_running?).and_return(true)
      @client.should_receive(:connect)
      @client.track('abc')
    end

    it 'starts the reactor if not already running' do
      EM.should_receive(:run).once
      @client.track('abc')
    end

    it 'warns when callbacks are passed as options' do
      @stream.stub(:each).and_yield(nil)
      Kernel.should_receive(:warn).with(/Passing callbacks via the options hash is deprecated and will be removed in TweetStream 3.0/)
      @client.track('abc', :inited => Proc.new { })
    end

    describe '#each' do
      it 'calls the appropriate parser' do
        @client = TweetStream::Client.new
        MultiJson.should_receive(:decode).and_return({})
        @stream.should_receive(:each).and_yield(sample_tweets[0].to_json)
        @client.track('abc','def')
      end

      it 'yields a Twitter::Tweet' do
        @stream.should_receive(:each).and_yield(sample_tweets[0].to_json)
        @client.track('abc'){|s| s.should be_kind_of(Twitter::Tweet)}
      end

      it 'yields the client if a block with arity 2 is given' do
        @stream.should_receive(:each).and_yield(sample_tweets[0].to_json)
        @client.track('abc'){|s,c| c.should == @client}
      end

      it 'includes the proper values' do
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

      it 'calls the on_stall_warning callback if specified' do
        @stream.should_receive(:each).and_yield(fixture('stall_warning.json'))
        @client.on_stall_warning do |warning|
          warning[:code].should eq('FALLING_BEHIND')
        end.track('abc')
      end

      it 'calls the on_scrub_geo callback if specified' do
        @stream.should_receive(:each).and_yield(fixture('scrub_geo.json'))
        @client.on_scrub_geo do |up_to_status_id, user_id|
          up_to_status_id.should == 9876
          user_id.should == 1234
        end.track('abc')
      end

      it 'calls the on_delete callback' do
        @stream.should_receive(:each).and_yield(fixture('delete.json'))
        @client.on_delete do |id, user_id|
          id.should == 1234
          user_id.should == 3
        end.track('abc')
      end

      it 'calls the on_limit callback' do
        limit = nil
        @stream.should_receive(:each).and_yield(fixture('limit.json'))
        @client.on_limit do |l|
          limit = l
        end.track('abc')

        limit.should eq(1234)
      end

      it 'calls the on_status_withheld callback' do
        status = nil
        @stream.should_receive(:each).and_yield(fixture('status_withheld.json'))
        @client.on_status_withheld do |s|
          status = s
        end.track('abc')

        status[:user_id].should eq(123456)
      end

      it 'calls the on_user_withheld callback' do
        status = nil
        @stream.should_receive(:each).and_yield(fixture('user_withheld.json'))
        @client.on_user_withheld do |s|
          status = s
        end.track('abc')

        status[:id].should eq(123456)
      end

      context "using on_anything" do
        it "yields the raw hash" do
          hash = {:id => 1234}
          @stream.should_receive(:each).and_yield(hash.to_json)
          yielded_hash = nil
          @client.on_anything do |h|
            yielded_hash = h
          end.track('abc')

          yielded_hash.should_not be_nil
          yielded_hash[:id].should eq(1234)
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
          direct_message[:direct_message][:id] = 1234
          direct_message[:direct_message][:sender][:screen_name] = "coder"
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
        @client.on_error { |m| true; }
        @client.on_error.should be_kind_of(Proc)
      end

      it 'should return nil when undefined' do
        @client.on_error.should be_nil
      end
    end

    describe '#on_max_reconnects' do
      it 'should raise a ReconnectError' do
        @stream.should_receive(:on_max_reconnects).and_yield(30, 20)
        lambda{ @client.track('abc') }.should raise_error(TweetStream::ReconnectError, "Failed to reconnect after 20 tries.")
      end
    end
  end

  describe 'API methods' do
    %w(firehose retweet sample links).each do |method|
      it "##{method} should make a call to start with \"statuses/#{method}\"" do
        @client.should_receive(:start).once.with('/1.1/statuses/' + method + '.json', {})
        @client.send(method)
      end
    end

    describe '#filter' do
      it 'makes a call to "statuses/filter" with the query params provided' do
        @client.should_receive(:start).once.with('/1.1/statuses/filter.json', :follow => 123, :method => :post)
        @client.filter(:follow => 123)
      end
      it 'makes a call to "statuses/filter" with the query params provided longitude/latitude pairs, separated by commas ' do
        @client.should_receive(:start).once.with('/1.1/statuses/filter.json', :locations => '-122.75,36.8,-121.75,37.8,-74,40,-73,41', :method => :post)
        @client.filter(:locations => '-122.75,36.8,-121.75,37.8,-74,40,-73,41')
      end
    end

    describe '#follow' do
      it 'makes a call to start with "statuses/filter" and a follow query parameter' do
        @client.should_receive(:start).once.with('/1.1/statuses/filter.json', :follow => [123], :method => :post)
        @client.follow(123)
      end

      it 'comma-joins multiple arguments' do
        @client.should_receive(:start).once.with('/1.1/statuses/filter.json', :follow => [123,456], :method => :post)
        @client.follow(123, 456)
      end
    end

    describe '#locations' do
      it 'should call #start with "statuses/filter" with the query params provided longitude/latitude pairs' do
        @client.should_receive(:start).once.with('/1.1/statuses/filter.json', :locations => ['-122.75,36.8,-121.75,37.8,-74,40,-73,41'], :method => :post)
        @client.locations('-122.75,36.8,-121.75,37.8,-74,40,-73,41')
      end

      it 'should call #start with "statuses/filter" with the query params provided longitude/latitude pairs and additional filter' do
        @client.should_receive(:start).once.with('/1.1/statuses/filter.json', :locations => ['-122.75,36.8,-121.75,37.8,-74,40,-73,41'], :track => 'rock', :method => :post)
        @client.locations('-122.75,36.8,-121.75,37.8,-74,40,-73,41', :track => 'rock')
      end
    end

    describe '#track' do
      it 'makes a call to start with "statuses/filter" and a track query parameter' do
        @client.should_receive(:start).once.with('/1.1/statuses/filter.json', :track => ['test'], :method => :post)
        @client.track('test')
      end

      it 'comma-joins multiple arguments' do
        @client.should_receive(:start).once.with('/1.1/statuses/filter.json', :track => ['foo', 'bar', 'baz'], :method => :post)
        @client.track('foo', 'bar', 'baz')
      end

      it 'comma-joins an array of arguments' do
        @client.should_receive(:start).once.with('/1.1/statuses/filter.json', :track => [['foo','bar','baz']], :method => :post)
        @client.track(['foo','bar','baz'])
      end

      it 'should call #start with "statuses/filter" and the provided queries' do
        @client.should_receive(:start).once.with('/1.1/statuses/filter.json', :track => ['rock'], :method => :post)
        @client.track('rock')
      end
    end
  end

  %w(on_delete on_limit on_inited on_reconnect on_no_data_received on_unauthorized on_enhance_your_calm).each do |proc_setter|
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
        :on_unauthorized => true,
        :on_enhance_your_calm => true,
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
end
