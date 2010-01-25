require File.dirname(__FILE__) + '/../spec_helper'

describe 'TweetStream JSON Parsers' do
  it 'should default to the JSON Gem' do
    TweetStream::Client.new('test','fake').parser.should == TweetStream::Parsers::JsonGem
  end
  
  [:json_gem, :yajl, :active_support, :json_pure].each do |engine|
    describe "#{engine} parsing" do
      before do
        @client = TweetStream::Client.new('test','fake',engine)
        @class_name = "TweetStream::Parsers::#{engine.to_s.split('_').map(&:capitalize).join('')}"
      end
      
      it 'should set the parser to the appropriate class' do
        @client.parser.to_s == @class_name
      end
      
      it 'should be settable via client.parser=' do
        @client.parser = nil
        @client.parser.should be_nil
        @client.parser = engine
        @client.parser.to_s.should == @class_name
      end
    end
  end
  
  class FakeParser
    def self.decode(text)
      {}
    end
  end
  
  it 'should be settable to a class' do
    @client = TweetStream::Client.new('abc','def')
    @client.parser = FakeParser
    @client.parser.should == FakeParser
  end
end