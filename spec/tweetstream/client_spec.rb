require 'helper'

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

  describe "#start" do
    before do
      @stream = double("EM::Twitter::Client",
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
      allow(EM).to receive(:run).and_yield
      allow(EM::Twitter::Client).to receive(:connect).and_return(@stream)
    end

    it "connects if the reactor is already running" do
      allow(EM).to receive(:reactor_running?).and_return(true)
      expect(@client).to receive(:connect)
      @client.track('abc')
    end

    it "starts the reactor if not already running" do
      expect(EM).to receive(:run).once
      @client.track('abc')
    end

    it "warns when callbacks are passed as options" do
      allow(@stream).to receive(:each).and_return
      expect(Kernel).to receive(:warn).with(/Passing callbacks via the options hash is deprecated and will be removed in TweetStream 3.0/)
      @client.track('abc', :inited => Proc.new { })
    end

    describe 'proxy usage' do
      it 'connects with a proxy' do
        @client = TweetStream::Client.new(:proxy => { :uri => 'http://someproxy:8081'})
        expect(EM::Twitter::Client).to receive(:connect).
          with(hash_including(:proxy => { :uri => 'http://someproxy:8081'})).and_return(@stream)
        expect(@stream).to receive(:each).and_return
        @client.track('abc')
      end
    end

    describe "#each" do
      it "calls the appropriate parser" do
        @client = TweetStream::Client.new
        expect(MultiJson).to receive(:decode).and_return({})
        expect(@stream).to receive(:each).and_yield(sample_tweets[0].to_json)
        @client.track('abc','def')
      end

      it "yields a Twitter::Tweet" do
        expect(@stream).to receive(:each).and_yield(sample_tweets[0].to_json)
        @client.track('abc'){|s| expect(s).to be_kind_of(Twitter::Tweet)}
      end

      it "yields the client if a block with arity 2 is given" do
        expect(@stream).to receive(:each).and_yield(sample_tweets[0].to_json)
        @client.track('abc'){|s,c| expect(c).to eq(@client)}
      end

      it "includes the proper values" do
        tweet = sample_tweets[0]
        tweet[:id] = 123
        tweet[:user][:screen_name] = 'monkey'
        tweet[:text] = "Oo oo aa aa"
        expect(@stream).to receive(:each).and_yield(tweet.to_json)
        @client.track('abc') do |s|
          expect(s[:id]).to eq(123)
          expect(s.user.screen_name).to eq('monkey')
          expect(s.text).to eq('Oo oo aa aa')
        end
      end

      it "calls the on_stall_warning callback if specified" do
        expect(@stream).to receive(:each).and_yield(fixture('stall_warning.json'))
        @client.on_stall_warning do |warning|
          expect(warning[:code]).to eq('FALLING_BEHIND')
        end.track('abc')
      end

      it "calls the on_scrub_geo callback if specified" do
        expect(@stream).to receive(:each).and_yield(fixture('scrub_geo.json'))
        @client.on_scrub_geo do |up_to_status_id, user_id|
          expect(up_to_status_id).to eq(9876)
          expect(user_id).to eq(1234)
        end.track('abc')
      end

      it "calls the on_delete callback" do
        expect(@stream).to receive(:each).and_yield(fixture('delete.json'))
        @client.on_delete do |id, user_id|
          expect(id).to eq(1234)
          expect(user_id).to eq(3)
        end.track('abc')
      end

      it "calls the on_limit callback" do
        limit = nil
        expect(@stream).to receive(:each).and_yield(fixture('limit.json'))
        @client.on_limit do |l|
          limit = l
        end.track('abc')

        expect(limit).to eq(1234)
      end

      it "calls the on_status_withheld callback" do
        status = nil
        expect(@stream).to receive(:each).and_yield(fixture('status_withheld.json'))
        @client.on_status_withheld do |s|
          status = s
        end.track('abc')

        expect(status[:user_id]).to eq(123456)
      end

      it "calls the on_user_withheld callback" do
        status = nil
        expect(@stream).to receive(:each).and_yield(fixture('user_withheld.json'))
        @client.on_user_withheld do |s|
          status = s
        end.track('abc')

        expect(status[:id]).to eq(123456)
      end

      context "using on_anything" do
        it "yields the raw hash" do
          hash = {:id => 1234}
          expect(@stream).to receive(:each).and_yield(hash.to_json)
          yielded_hash = nil
          @client.on_anything do |h|
            yielded_hash = h
          end.track('abc')

          expect(yielded_hash).not_to be_nil
          expect(yielded_hash[:id]).to eq(1234)
        end
        it "yields itself if block has an arity of 2" do
          hash = {:id => 1234}
          expect(@stream).to receive(:each).and_yield(hash.to_json)
          yielded_client = nil
          @client.on_anything do |_, client|
            yielded_client = client
          end.track('abc')
          expect(yielded_client).not_to be_nil
          expect(yielded_client).to eq(@client)
        end
      end

      context "using on_timeline_status" do
        it "yields a Status" do
          tweet = sample_tweets[0]
          tweet[:id] = 123
          tweet[:user][:screen_name] = 'monkey'
          tweet[:text] = "Oo oo aa aa"
          expect(@stream).to receive(:each).and_yield(tweet.to_json)
          yielded_status = nil
          @client.on_timeline_status do |status|
            yielded_status = status
          end.track('abc')
          expect(yielded_status).not_to be_nil
          expect(yielded_status[:id]).to eq(123)
          expect(yielded_status.user.screen_name).to eq('monkey')
          expect(yielded_status.text).to eq('Oo oo aa aa')
        end
        it "yields itself if block has an arity of 2" do
          expect(@stream).to receive(:each).and_yield(sample_tweets[0].to_json)
          yielded_client = nil
          @client.on_timeline_status do |_, client|
            yielded_client = client
          end.track('abc')
          expect(yielded_client).not_to be_nil
          expect(yielded_client).to eq(@client)
        end
      end

      context "using on_direct_message" do
        it "yields a DirectMessage" do
          direct_message = sample_direct_messages[0]
          direct_message[:direct_message][:id] = 1234
          direct_message[:direct_message][:sender][:screen_name] = "coder"
          expect(@stream).to receive(:each).and_yield(direct_message.to_json)
          yielded_dm = nil
          @client.on_direct_message do |dm|
            yielded_dm = dm
          end.userstream
          expect(yielded_dm).not_to be_nil
          expect(yielded_dm.id).to eq(1234)
          expect(yielded_dm.sender.screen_name).to eq("coder")
        end

        it "yields itself if block has an arity of 2" do
          expect(@stream).to receive(:each).and_yield(sample_direct_messages[0].to_json)
          yielded_client = nil
          @client.on_direct_message do |_, client|
            yielded_client = client
          end.userstream
          expect(yielded_client).to eq(@client)
        end
      end

      it "calls on_error if a non-hash response is received" do
        expect(@stream).to receive(:each).and_yield('["favorited"]')
        @client.on_error do |message|
          expect(message).to eq('Unexpected JSON object in stream: ["favorited"]')
        end.track('abc')
      end

      it "calls on_error if a json parse error occurs" do
        expect(@stream).to receive(:each).and_yield("{'a_key':}")
        @client.on_error do |message|
          expect(message).to eq("MultiJson::DecodeError occured in stream: {'a_key':}")
        end.track('abc')
      end
    end

    describe "#on_error" do
      it "passes the message on to the error block" do
        expect(@stream).to receive(:on_error).and_yield('Uh oh')
        @client.on_error do |m|
          expect(m).to eq('Uh oh')
        end.track('abc')
      end

      it "returns the block when defined" do
        @client.on_error { |m| true; }
        expect(@client.on_error).to be_kind_of(Proc)
      end

      it "returns nil when undefined" do
        expect(@client.on_error).to be_nil
      end
    end

    describe "#on_max_reconnects" do
      it "raises a ReconnectError" do
        expect(@stream).to receive(:on_max_reconnects).and_yield(30, 20)
        expect(lambda{ @client.track('abc') }).to raise_error(TweetStream::ReconnectError, "Failed to reconnect after 20 tries.")
      end
    end
  end

  describe "API methods" do
    %w(firehose retweet sample links).each do |method|
      it "##{method} should make a call to start with \"statuses/#{method}\"" do
        expect(@client).to receive(:start).once.with('/1.1/statuses/' + method + '.json', {})
        @client.send(method)
      end
    end

    describe "#filter" do
      it "makes a call to 'statuses/filter' with the query params provided" do
        expect(@client).to receive(:start).once.with('/1.1/statuses/filter.json', :follow => 123, :method => :post)
        @client.filter(:follow => 123)
      end
      it "makes a call to 'statuses/filter' with the query params provided longitude/latitude pairs, separated by commas " do
        expect(@client).to receive(:start).once.with('/1.1/statuses/filter.json', :locations => '-122.75,36.8,-121.75,37.8,-74,40,-73,41', :method => :post)
        @client.filter(:locations => '-122.75,36.8,-121.75,37.8,-74,40,-73,41')
      end
    end

    describe "#follow" do
      it "makes a call to start with 'statuses/filter' and a follow query parameter" do
        expect(@client).to receive(:start).once.with('/1.1/statuses/filter.json', :follow => [123], :method => :post)
        @client.follow(123)
      end

      it "comma-joins multiple arguments" do
        expect(@client).to receive(:start).once.with('/1.1/statuses/filter.json', :follow => [123,456], :method => :post)
        @client.follow(123, 456)
      end
    end

    describe "#locations" do
      it "calls #start with 'statuses/filter' with the query params provided longitude/latitude pairs" do
        expect(@client).to receive(:start).once.with('/1.1/statuses/filter.json', :locations => ['-122.75,36.8,-121.75,37.8,-74,40,-73,41'], :method => :post)
        @client.locations('-122.75,36.8,-121.75,37.8,-74,40,-73,41')
      end

      it "calls #start with 'statuses/filter' with the query params provided longitude/latitude pairs and additional filter" do
        expect(@client).to receive(:start).once.with('/1.1/statuses/filter.json', :locations => ['-122.75,36.8,-121.75,37.8,-74,40,-73,41'], :track => 'rock', :method => :post)
        @client.locations('-122.75,36.8,-121.75,37.8,-74,40,-73,41', :track => 'rock')
      end
    end

    describe "#track" do
      it "makes a call to start with 'statuses/filter' and a track query parameter" do
        expect(@client).to receive(:start).once.with('/1.1/statuses/filter.json', :track => ['test'], :method => :post)
        @client.track('test')
      end

      it "comma-joins multiple arguments" do
        expect(@client).to receive(:start).once.with('/1.1/statuses/filter.json', :track => ['foo', 'bar', 'baz'], :method => :post)
        @client.track('foo', 'bar', 'baz')
      end

      it "comma-joins an array of arguments" do
        expect(@client).to receive(:start).once.with('/1.1/statuses/filter.json', :track => [['foo','bar','baz']], :method => :post)
        @client.track(['foo','bar','baz'])
      end

      it "calls #start with 'statuses/filter' and the provided queries" do
        expect(@client).to receive(:start).once.with('/1.1/statuses/filter.json', :track => ['rock'], :method => :post)
        @client.track('rock')
      end
    end
  end

  %w(on_delete on_limit on_inited on_reconnect on_no_data_received on_unauthorized on_enhance_your_calm).each do |proc_setter|
    describe "##{proc_setter}" do
      it "sets when a block is given" do
        proc = Proc.new{|a,b| puts a }
        @client.send(proc_setter, &proc)
        expect(@client.send(proc_setter)).to eq(proc)
      end

      it "returns nil when undefined" do
        expect(@client.send(proc_setter)).to be_nil
      end
    end
  end

  describe "#stop" do
    it "calls EventMachine::stop_event_loop" do
      expect(EventMachine).to receive(:stop_event_loop)
      expect(TweetStream::Client.new.stop).to be_nil
    end

    it "returns the last status yielded" do
      expect(EventMachine).to receive(:stop_event_loop)
      client = TweetStream::Client.new
      client.send(:instance_variable_set, :@last_status, {})
      expect(client.stop).to eq({})
    end
  end

  describe "#close_connection" do
    it "does not call EventMachine::stop_event_loop" do
      expect(EventMachine).not_to receive(:stop_event_loop)
      expect(TweetStream::Client.new.close_connection).to be_nil
    end
  end

  describe "#stop_stream" do
    before(:each) do
      @stream = double("EM::Twitter::Client",
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
      allow(EM::Twitter::Client).to receive(:connect).and_return(@stream)
      @client = TweetStream::Client.new
      @client.connect('/')
    end

    it "calls stream.stop to cleanly stop the current stream" do
      expect(@stream).to receive(:stop)
      @client.stop_stream
    end

    it "does not stop eventmachine" do
      expect(EventMachine).not_to receive(:stop_event_loop)
      @client.stop_stream
    end
  end
end
