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

  describe "User Stream support" do
    context 'when calling #userstream' do
      it "sends the userstream host" do
        EM::Twitter::Client.should_receive(:connect).with(hash_including(:host => "userstream.twitter.com")).and_return(@stream)
        @client.userstream
      end

      it "uses the userstream uri" do
        EM::Twitter::Client.should_receive(:connect).with(hash_including(:path => "/2/user.json")).and_return(@stream)
        @client.userstream
      end
    end
  end

end
