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

  describe "Site Stream support" do
    context "when calling #sitestream" do
      it "sends the sitestream host" do
        EM::Twitter::Client.should_receive(:connect).with(hash_including(:host => "sitestream.twitter.com")).and_return(@stream)
        @client.sitestream
      end

      it "uses the sitestream uri" do
        EM::Twitter::Client.should_receive(:connect).with(hash_including(:path => "/2b/site.json")).and_return(@stream)
        @client.sitestream
      end

      it 'supports "with followings" when followings set as a boolean' do
        @client.should_receive(:start).once.with('', hash_including(:with => 'followings')).and_return(@stream)
        @client.sitestream(['115192457'], :followings => true)
      end

      it 'supports "with followings" when followings set as an option' do
        @client.should_receive(:start).once.with('', hash_including(:with => 'followings')).and_return(@stream)
        @client.sitestream(['115192457'], :with => 'followings')
      end

      it 'supports "with user"' do
        @client.should_receive(:start).once.with('', hash_including(:with => 'user')).and_return(@stream)
        @client.sitestream(['115192457'], :with => 'user')
      end

      it 'supports "replies all"' do
        @client.should_receive(:start).once.with('', hash_including(:replies => 'all')).and_return(@stream)
        @client.sitestream(['115192457'], :replies => 'all')
      end

      context 'control management' do
        before do
          @control_response = {"control" =>
            {
              "control_uri" =>"/2b/site/c/01_225167_334389048B872A533002B34D73F8C29FD09EFC50"
            }
          }
        end
        it 'assigns the control_uri' do
          @stream.should_receive(:each).and_yield(@control_response.to_json)
          @client.sitestream

          @client.control_uri.should eq("/2b/site/c/01_225167_334389048B872A533002B34D73F8C29FD09EFC50")
        end

        it 'instantiates a SiteStreamClient' do
          @stream.should_receive(:each).and_yield(@control_response.to_json)
          @client.sitestream

          @client.control.should be_kind_of(TweetStream::SiteStreamClient)
        end

        it "passes the client's on_error to the SiteStreamClient" do
          called = false
          @client.on_error { |err| called = true }
          @stream.should_receive(:each).and_yield(@control_response.to_json)
          @client.sitestream

          @client.control.on_error.call

          called.should be_true
        end
      end

      context 'data handling' do
        before do
          tweet = sample_tweets[0]
          @ss_message = {'for_user' => '12345', 'message' => {'id' => 123, 'user' => {'screen_name' => 'monkey'}, 'text' => 'Oo oo aa aa'}}
        end

        it 'yields a site stream message' do
          @stream.should_receive(:each).and_yield(@ss_message.to_json)
          yielded_status = nil
          @client.sitestream do |message|
            yielded_status = message
          end
          yielded_status.should_not be_nil
          yielded_status[:for_user].should == '12345'
          yielded_status[:message][:user][:screen_name].should == 'monkey'
          yielded_status[:message][:text].should == 'Oo oo aa aa'
        end
        it 'yields itself if block has an arity of 2' do
          @stream.should_receive(:each).and_yield(@ss_message.to_json)
          yielded_client = nil
          @client.sitestream do |_, client|
            yielded_client = client
          end
          yielded_client.should_not be_nil
          yielded_client.should == @client
        end
      end
    end
  end

end
