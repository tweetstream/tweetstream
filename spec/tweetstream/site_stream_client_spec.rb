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

  describe '#on_error' do
    it 'stores the on_error proc' do
      @client = TweetStream::SiteStreamClient.new('/config_uri')
      @client.on_error { puts 'hi' }
      @client.on_error.should be_kind_of(Proc)
    end
  end

  describe '#info' do
    context 'success' do
      it 'returns the information hash' do
        @config_uri = '/2b/site/c/1_1_54e345d655ee3e8df359ac033648530bfbe26c5f'
        @client = TweetStream::SiteStreamClient.new(@config_uri)

        stub_request(:get, "https://sitestream.twitter.com#{@config_uri}/info.json").
          to_return(:status => 200, :body => fixture('info.json'), :headers => {})
        stream_info = nil

        EM.run_block do
          @client.info { |info| stream_info = info}
        end
        stream_info.should be_kind_of(Hash)
      end
    end

    context 'failure' do
      it 'invokes the on_error callback' do
        @config_uri = '/2b/site/c/1_1_54e345d655ee3e8df359ac033648530bfbe26c5g'
        @client = TweetStream::SiteStreamClient.new(@config_uri)

        stub_request(:get, "https://sitestream.twitter.com#{@config_uri}/info.json").
          to_return(:status => 401, :body => '', :headers => {})
        called = false

        EM.run_block do
          @client.on_error { called = true }
          @client.info { |info| info }
        end
        called.should be_true
      end
    end
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