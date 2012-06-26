require 'spec_helper'

describe TweetStream do
  after do
    TweetStream.reset
  end

  context "when delegating to a client" do
    before do
      @stream = stub("EM::Twitter::Client",
        :connect => true,
        :unbind => true,
        :each_item => true,
        :on_error => true,
        :on_max_reconnects => true,
        :on_reconnect => true,
        :connection_completed => true,
        :on_no_data_received => true,
        :on_unauthorized => true
      )
      EM.stub!(:run).and_yield
      EM::Twitter::Client.stub!(:connect).and_return(@stream)
    end

    it "should return the same results as a client" do
      MultiJson.should_receive(:decode).and_return({})
      @stream.should_receive(:each).and_yield(sample_tweets[0].to_json)
      TweetStream.track('abc','def')
    end
  end

  describe ".new" do
    it "should be a TweetStream::Client" do
      TweetStream.new.should be_a TweetStream::Client
    end
  end

  describe '.respond_to?' do
    it "should take an optional argument" do
      TweetStream.respond_to?(:new, true).should be_true
    end
  end

  describe ".username" do
    it "should return the default username" do
      TweetStream.username.should == TweetStream::Configuration::DEFAULT_USERNAME
    end
  end

  describe ".username=" do
    it "should set the username" do
      TweetStream.username = 'jack'
      TweetStream.username.should == 'jack'
    end
  end

  describe ".password" do
    it "should return the default password" do
      TweetStream.password.should == TweetStream::Configuration::DEFAULT_PASSWORD
    end
  end

  describe ".password=" do
    it "should set the password" do
      TweetStream.password = 'passw0rd'
      TweetStream.password.should == 'passw0rd'
    end
  end

  describe ".auth_method" do
    it "shold return the default auth method" do
      TweetStream.auth_method.should == TweetStream::Configuration::DEFAULT_AUTH_METHOD
    end
  end

  describe ".auth_method=" do
    it "should set the auth method" do
      TweetStream.auth_method = :basic
      TweetStream.auth_method.should == :basic
    end
  end

  describe ".user_agent" do
    it "should return the default user agent" do
      TweetStream.user_agent.should == TweetStream::Configuration::DEFAULT_USER_AGENT
    end
  end

  describe ".user_agent=" do
    it "should set the user_agent" do
      TweetStream.user_agent = 'Custom User Agent'
      TweetStream.user_agent.should == 'Custom User Agent'
    end
  end

  describe ".configure" do
    TweetStream::Configuration::VALID_OPTIONS_KEYS.each do |key|
      it "should set the #{key}" do
        TweetStream.configure do |config|
          config.send("#{key}=", key)
          TweetStream.send(key).should == key
        end
      end
    end
  end

  describe '.options' do
    it 'returns the configuration as a hash' do
      TweetStream.options.should be_kind_of(Hash)
    end
  end

  describe '.oauth_options' do
    it 'returns the oauth configuration as a hash' do
      TweetStream.oauth_options.should be_kind_of(Hash)
    end
  end

end
