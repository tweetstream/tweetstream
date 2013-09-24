require 'helper'

describe TweetStream do

  context "when delegating to a client" do
    before do
      @stream = double("EM::Twitter::Client",
        :connect => true,
        :unbind => true,
        :each_item => true,
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

    it "returns the same results as a client" do
      expect(MultiJson).to receive(:decode).and_return({})
      expect(@stream).to receive(:each).and_yield(sample_tweets[0].to_json)
      TweetStream.track('abc','def')
    end
  end

  describe ".new" do
    it "is a TweetStream::Client" do
      expect(TweetStream.new).to be_a TweetStream::Client
    end
  end

  describe ".respond_to?" do
    it "takes an optional argument" do
      expect(TweetStream.respond_to?(:new, true)).to be_true
    end
  end

  describe ".username" do
    it "returns the default username" do
      expect(TweetStream.username).to eq(TweetStream::Configuration::DEFAULT_USERNAME)
    end
  end

  describe ".username=" do
    it "sets the username" do
      TweetStream.username = 'jack'
      expect(TweetStream.username).to eq('jack')
    end
  end

  describe ".password" do
    it "returns the default password" do
      expect(TweetStream.password).to eq(TweetStream::Configuration::DEFAULT_PASSWORD)
    end
  end

  describe ".password=" do
    it "sets the password" do
      TweetStream.password = 'passw0rd'
      expect(TweetStream.password).to eq('passw0rd')
    end
  end

  describe ".auth_method" do
    it "shold return the default auth method" do
      expect(TweetStream.auth_method).to eq(TweetStream::Configuration::DEFAULT_AUTH_METHOD)
    end
  end

  describe ".auth_method=" do
    it "sets the auth method" do
      TweetStream.auth_method = :basic
      expect(TweetStream.auth_method).to eq(:basic)
    end
  end

  describe ".user_agent" do
    it "returns the default user agent" do
      expect(TweetStream.user_agent).to eq(TweetStream::Configuration::DEFAULT_USER_AGENT)
    end
  end

  describe ".user_agent=" do
    it "sets the user_agent" do
      TweetStream.user_agent = 'Custom User Agent'
      expect(TweetStream.user_agent).to eq('Custom User Agent')
    end
  end

  describe ".configure" do
    TweetStream::Configuration::VALID_OPTIONS_KEYS.each do |key|
      it "sets the #{key}" do
        TweetStream.configure do |config|
          config.send("#{key}=", key)
          expect(TweetStream.send(key)).to eq(key)
        end
      end
    end
  end

  describe ".options" do
    it "returns the configuration as a hash" do
      expect(TweetStream.options).to be_kind_of(Hash)
    end
  end

  describe ".oauth_options" do
    it "returns the oauth configuration as a hash" do
      expect(TweetStream.oauth_options).to be_kind_of(Hash)
    end
  end

  describe '.proxy' do
    it 'returns the default proxy' do
      expect(TweetStream.proxy).to eq(TweetStream::Configuration::DEFAULT_PROXY)
    end
  end

  describe '.proxy=' do
    it 'sets the proxy' do
      TweetStream.proxy = { :uri => 'http://someproxy:8081' }
      expect(TweetStream.proxy).to be_kind_of(Hash)
    end
  end
end
