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

  describe "User Stream support" do
    context "when calling #userstream" do
      it "sends the userstream host" do
        expect(EM::Twitter::Client).to receive(:connect).with(hash_including(:host => "userstream.twitter.com")).and_return(@stream)
        @client.userstream
      end

      it "uses the userstream uri" do
        expect(@client).to receive(:start).once.with("/1.1/user.json", an_instance_of(Hash)).and_return(@stream)
        @client.userstream
      end

      it "supports :replies => 'all'" do
        expect(@client).to receive(:start).once.with("/1.1/user.json", hash_including(:replies => 'all')).and_return(@stream)
        @client.userstream(:replies => 'all')
      end

      it "supports :stall_warnings => 'true'" do
        expect(@client).to receive(:start).once.with("/1.1/user.json", hash_including(:stall_warnings => 'true')).and_return(@stream)
        @client.userstream(:stall_warnings => 'true')
      end

      it "supports :with => 'followings'" do
        expect(@client).to receive(:start).once.with("/1.1/user.json", hash_including(:with => 'followings')).and_return(@stream)
        @client.userstream(:with => 'followings')
      end

      it "supports :with => 'user'" do
        expect(@client).to receive(:start).once.with("/1.1/user.json", hash_including(:with => 'user')).and_return(@stream)
        @client.userstream(:with => 'user')
      end

      it "supports event callbacks" do
        event = nil
        expect(@stream).to receive(:each).and_yield(fixture('favorite.json'))
        @client.on_event(:favorite) do |e|
          event = e
        end.userstream

        expect(event[:source]).not_to be_nil
        expect(event[:target]).not_to be_nil
      end
    end
  end

end
