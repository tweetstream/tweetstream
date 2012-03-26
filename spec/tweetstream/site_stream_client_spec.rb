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
    context 'success' do
      it 'calls a block (if passed one)' do
        @config_uri = '/2b/site/c/1_1_54e345d655ee3e8df359ac033648530bfbe26c5f'
        @client = TweetStream::SiteStreamClient.new(@config_uri)

        stub_request(:post, "https://sitestream.twitter.com#{@config_uri}/add_user.json").
          to_return(:status => 200, :body => '', :headers => {})
        called = false

        EM.run_block do
          @client.add_user(12345) { called = true }
        end
        called.should be_true
      end
    end

    context 'failure' do
      it 'invokes the on_error callback' do
        @config_uri = '/2b/site/c/1_1_54e345d655ee3e8df359ac033648530bfbe26c5g'
        @client = TweetStream::SiteStreamClient.new(@config_uri)

        stub_request(:post, "https://sitestream.twitter.com#{@config_uri}/add_user.json").
          to_return(:status => 401, :body => '', :headers => {})
        called = false

        EM.run_block do
          @client.on_error { called = true }
          @client.add_user(12345) { |info| info }
        end
        called.should be_true
      end
    end

    it 'accepts an array of user_ids' do
      @client = TweetStream::SiteStreamClient.new('/config_uri')
      conn = stub('Connection')
      conn.should_receive(:post).
        with(:path => '/config_uri/add_user.json', :body => { 'user_id' => '1234,5678' }).
        and_return(FakeHttp.new)
      @client.stub(:connection) { conn }
      @client.add_user(['1234','5678'])
    end
  end

  describe '#remove_user' do
    context 'success' do
      it 'calls a block (if passed one)' do
        @config_uri = '/2b/site/c/1_1_54e345d655ee3e8df359ac033648530bfbe26c5f'
        @client = TweetStream::SiteStreamClient.new(@config_uri)

        stub_request(:post, "https://sitestream.twitter.com#{@config_uri}/remove_user.json").
          to_return(:status => 200, :body => '', :headers => {})
        called = false

        EM.run_block do
          @client.remove_user(12345) { called = true }
        end
        called.should be_true
      end
    end

    context 'failure' do
      it 'invokes the on_error callback' do
        @config_uri = '/2b/site/c/1_1_54e345d655ee3e8df359ac033648530bfbe26c5g'
        @client = TweetStream::SiteStreamClient.new(@config_uri)

        stub_request(:post, "https://sitestream.twitter.com#{@config_uri}/remove_user.json").
          to_return(:status => 401, :body => '', :headers => {})
        called = false

        EM.run_block do
          @client.on_error { called = true }
          @client.remove_user(12345) { |info| info }
        end
        called.should be_true
      end
    end

    it 'accepts an array of user_ids' do
      @client = TweetStream::SiteStreamClient.new('/config_uri')
      conn = stub('Connection')
      conn.should_receive(:post).
        with(:path => '/config_uri/remove_user.json', :body => { 'user_id' => '1234,5678' }).
        and_return(FakeHttp.new)
      @client.stub(:connection) { conn }
      @client.remove_user(['1234','5678'])
    end
  end

  describe '#friends_ids' do
    context 'success' do
      it 'returns the information hash' do
        @config_uri = '/2b/site/c/1_1_54e345d655ee3e8df359ac033648530bfbe26c5f'
        @client = TweetStream::SiteStreamClient.new(@config_uri)

        stub_request(:post, "https://sitestream.twitter.com#{@config_uri}/friends/ids.json").
          to_return(:status => 200, :body => fixture('ids.json'), :headers => {})
        stream_info = nil

        EM.run_block do
          @client.friends_ids(12345) { |info| stream_info = info }
        end
        stream_info.should be_kind_of(Hash)
      end
    end

    context 'failure' do
      it 'invokes the on_error callback' do
        @config_uri = '/2b/site/c/1_1_54e345d655ee3e8df359ac033648530bfbe26c5g'
        @client = TweetStream::SiteStreamClient.new(@config_uri)

        stub_request(:post, "https://sitestream.twitter.com#{@config_uri}/friends/ids.json").
          to_return(:status => 401, :body => '', :headers => {})
        called = false

        EM.run_block do
          @client.on_error { called = true }
          @client.friends_ids(12345) { |info| info }
        end
        called.should be_true
      end
    end
  end

end