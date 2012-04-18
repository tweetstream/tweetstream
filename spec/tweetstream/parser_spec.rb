require 'spec_helper'

describe 'TweetStream MultiJson Support' do
  after do
    TweetStream.reset
  end

  it "should default to the MultiJson default's parser" do
    TweetStream::Client.new.json_parser.adapter.to_s.should == MultiJson.adapter.to_s
  end

  [:json_gem, :yajl, :json_pure].each do |adapter|
    describe "#{adapter} parsing" do
      before do
        TweetStream.configure do |config|
          config.username = 'test'
          config.password = 'fake'
          config.parser   = adapter
        end
        @client = TweetStream::Client.new
        @class_name = "MultiJson::Adapters::#{adapter.to_s.split('_').map{|s| s.capitalize}.join('')}"
      end

      it 'should set the parser to the appropriate class' do
        @client.json_parser.adapter.to_s == @class_name
      end

      it 'should be settable via client.parser=' do
        @client.parser = adapter
        @client.json_parser.adapter.to_s.should == @class_name
      end
    end
  end

  class FakeParser; end

  it 'should be settable to a class' do
    @client = TweetStream::Client.new
    @client.parser = FakeParser
    @client.json_parser.adapter.should == FakeParser
  end
end