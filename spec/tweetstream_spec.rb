require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe TweetStream do
  after do
    TweetStream.reset
  end

  context "when delegating to a client" do
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

    it "should return the same results as a client" do
      MultiJson.should_receive(:decode).and_return({})
      @stream.should_receive(:each_item).and_yield(sample_tweets[0].to_json)
      TweetStream.track('abc','def')
      # @client.track('abc','def')
      # TweetStream.user_timeline('sferik').should == TweetStream::Client.new.user_timeline('sferik')
    end
  end

  describe ".client" do
    it "should be a TweetStream::Client" do
      TweetStream.client.should be_a TweetStream::Client
    end
  end

  describe ".parser" do
    it "should return the default parser" do
      TweetStream.parser.should == TweetStream::Configuration::DEFAULT_PARSER
    end
  end

  describe ".parser=" do
    it "should set the adapter" do
      TweetStream.parser = :yajl
      TweetStream.parser.should == :yajl
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

end
