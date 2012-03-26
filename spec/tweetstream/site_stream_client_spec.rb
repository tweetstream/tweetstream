require 'spec_helper'

describe TweetStream::SiteStreamClient do
  before do
    @keys = TweetStream::Configuration::OAUTH_OPTIONS_KEYS
  end

  describe 'initialization' do
    context 'with module configuration' do

      before do
        TweetStream.configure do |config|
          @keys.each do |key|
            config.send("#{key}=", key)
          end
        end
      end

      after do
        TweetStream.reset
      end

      it "should inherit module configuration" do
        api = TweetStream::SiteStreamClient.new('/config_uri')
        @keys.each do |key|
          api.send(key).should == key
        end
      end
    end

    context 'with class configuration' do
      before do
        @configuration = {
          :consumer_key => 'CK',
          :consumer_secret => 'CS',
          :oauth_token => 'AT',
          :oauth_token_secret => 'AS'
        }
      end

      context "during initialization" do
        it "should override module configuration" do
          api = TweetStream::SiteStreamClient.new('/config_uri', @configuration)
          @keys.each do |key|
            api.send(key).should == @configuration[key]
          end
        end
      end

      context "after initilization" do
        it "should override module configuration after initialization" do
          api = TweetStream::SiteStreamClient.new('/config_uri')
          @configuration.each do |key, value|
            api.send("#{key}=", value)
          end
          @keys.each do |key|
            api.send(key).should == @configuration[key]
          end
        end
      end
    end
  end

  describe '#info' do
    pending
  end

  describe '#add_user' do
    pending
  end

  describe '#remove_user' do
    pending
  end

  describe '#ids' do
    pending
  end

end