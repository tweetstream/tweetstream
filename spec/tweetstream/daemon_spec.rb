require 'spec_helper'

describe TweetStream::Daemon do
  describe '.new' do
    it 'initializes with no arguments' do
      client = TweetStream::Daemon.new
      client.should be_kind_of(TweetStream::Client)
    end

    it 'initializes with defaults' do
      client = TweetStream::Daemon.new
      client.app_name.should eq(TweetStream::Daemon::DEFAULT_NAME)
      client.daemon_options.should eq(TweetStream::Daemon::DEFAULT_OPTIONS)
    end

    it 'initializes with an app_name' do
      client = TweetStream::Daemon.new('tweet_tracker')
      client.app_name.should eq('tweet_tracker')
    end
  end
end
