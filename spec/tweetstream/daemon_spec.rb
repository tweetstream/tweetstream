require 'helper'

describe TweetStream::Daemon do
  describe ".new" do
    it "initializes with no arguments" do
      client = TweetStream::Daemon.new
      expect(client).to be_kind_of(TweetStream::Client)
    end

    it "initializes with defaults" do
      client = TweetStream::Daemon.new
      expect(client.app_name).to eq(TweetStream::Daemon::DEFAULT_NAME)
      expect(client.daemon_options).to eq(TweetStream::Daemon::DEFAULT_OPTIONS)
    end

    it "initializes with an app_name" do
      client = TweetStream::Daemon.new('tweet_tracker')
      expect(client.app_name).to eq('tweet_tracker')
    end
  end

  describe "#start" do
    it "starts the daemon" do
      client = TweetStream::Daemon.new
      expect(Daemons).to receive(:run_proc).once
      client.track('intridea')
    end
  end
end
