require 'helper'

describe TweetStream::Client do
  before(:each) do
    TweetStream.configure do |config|
      config.consumer_key = 'abc'
      config.consumer_secret = 'def'
      config.oauth_token = '123'
      config.oauth_token_secret = '456'
    end
    @client = TweetStream::Client.new

    @stream = double("EM::Twitter::Client",
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
    allow(EM).to receive(:run).and_yield
    allow(EM::Twitter::Client).to receive(:connect).and_return(@stream)
  end

  describe "Site Stream support" do
    context "when calling #sitestream" do
      it "sends the sitestream host" do
        expect(EM::Twitter::Client).to receive(:connect).with(hash_including(:host => "sitestream.twitter.com")).and_return(@stream)
        @client.sitestream
      end

      it "uses the sitestream uri" do
        expect(@client).to receive(:start).once.with('/1.1/site.json', an_instance_of(Hash)).and_return(@stream)
        @client.sitestream
      end

      it "supports :followings => true" do
        expect(@client).to receive(:start).once.with('/1.1/site.json', hash_including(:with => 'followings')).and_return(@stream)
        @client.sitestream(['115192457'], :followings => true)
      end

      it "supports :with => 'followings'" do
        expect(@client).to receive(:start).once.with('/1.1/site.json', hash_including(:with => 'followings')).and_return(@stream)
        @client.sitestream(['115192457'], :with => 'followings')
      end

      it "supports :with => 'user'" do
        expect(@client).to receive(:start).once.with('/1.1/site.json', hash_including(:with => 'user')).and_return(@stream)
        @client.sitestream(['115192457'], :with => 'user')
      end

      it "supports :replies => 'all'" do
        expect(@client).to receive(:start).once.with('/1.1/site.json', hash_including(:replies => 'all')).and_return(@stream)
        @client.sitestream(['115192457'], :replies => 'all')
      end

      describe "control management" do
        before do
          @control_response = {"control" =>
            {
              "control_uri" =>"/1.1/site/c/01_225167_334389048B872A533002B34D73F8C29FD09EFC50"
            }
          }
        end
        it "assigns the control_uri" do
          expect(@stream).to receive(:each).and_yield(@control_response.to_json)
          @client.sitestream

          expect(@client.control_uri).to eq("/1.1/site/c/01_225167_334389048B872A533002B34D73F8C29FD09EFC50")
        end

        it 'invokes the on_control callback' do
          called = false
          expect(@stream).to receive(:each).and_yield(@control_response.to_json)
          @client.on_control { called = true }
          @client.sitestream

          expect(called).to be_true
        end

        it 'is controllable when a control_uri has been received' do
          expect(@stream).to receive(:each).and_yield(@control_response.to_json)
          @client.sitestream

          expect(@client.controllable?).to be_true
        end

        it "instantiates a SiteStreamClient" do
          expect(@stream).to receive(:each).and_yield(@control_response.to_json)
          @client.sitestream

          expect(@client.control).to be_kind_of(TweetStream::SiteStreamClient)
        end

        it "passes the client's on_error to the SiteStreamClient" do
          called = false
          @client.on_error { |err| called = true }
          expect(@stream).to receive(:each).and_yield(@control_response.to_json)
          @client.sitestream

          @client.control.on_error.call

          expect(called).to be_true
        end
      end

      describe "data handling" do
        context "messages" do
          before do
            @ss_message = {'for_user' => '12345', 'message' => {'id' => 123, 'user' => {'screen_name' => 'monkey'}, 'text' => 'Oo oo aa aa'}}
          end

          it "yields a site stream message" do
            expect(@stream).to receive(:each).and_yield(@ss_message.to_json)
            yielded_status = nil
            @client.sitestream do |message|
              yielded_status = message
            end
            expect(yielded_status).not_to be_nil
            expect(yielded_status[:for_user]).to eq('12345')
            expect(yielded_status[:message][:user][:screen_name]).to eq('monkey')
            expect(yielded_status[:message][:text]).to eq('Oo oo aa aa')
          end
          it "yields itself if block has an arity of 2" do
            expect(@stream).to receive(:each).and_yield(@ss_message.to_json)
            yielded_client = nil
            @client.sitestream do |_, client|
              yielded_client = client
            end
            expect(yielded_client).not_to be_nil
            expect(yielded_client).to eq(@client)
          end
        end

        context "friends list" do
          before do
            @friends_list = { 'friends' => [123, 456] }
         end

          it "yields a friends list array" do
            expect(@stream).to receive(:each).and_yield(@friends_list.to_json)
            yielded_list = nil
            @client.on_friends do |friends|
              yielded_list = friends
            end
            @client.sitestream

            expect(yielded_list).not_to be_nil
            expect(yielded_list).to be_an(Array)
            expect(yielded_list.first).to eq(123)
          end
        end
      end
    end
  end

end
