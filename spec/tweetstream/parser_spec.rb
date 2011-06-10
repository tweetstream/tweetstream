require File.dirname(__FILE__) + '/../spec_helper'

describe 'TweetStream MultiJson Support' do
  it 'should default to the JSON Gem' do
    TweetStream::Client.new('test','fake').parser.engine.should == MultiJson::Engines::JsonGem
  end

  [:json_gem, :yajl, :json_pure].each do |engine|
    describe "#{engine} parsing" do
      before do
        @client = TweetStream::Client.new('test','fake',engine)
        @class_name = "MultiJson::Engines::#{engine.to_s.split('_').map{|s| s.capitalize}.join('')}"
      end

      it 'should set the parser to the appropriate class' do
        @client.parser.engine.to_s == @class_name
      end

      it 'should be settable via client.parser=' do
        @client.parser = engine
        @client.parser.engine.to_s.should == @class_name
      end
    end
  end

  class FakeParser; end

  it 'should be settable to a class' do
    @client = TweetStream::Client.new('abc','def')
    @client.parser = FakeParser
    @client.parser.engine.should == FakeParser
  end
end