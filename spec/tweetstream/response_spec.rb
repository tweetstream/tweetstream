require 'spec_helper'

describe TweetStream::Response do
  describe 'initialization' do
    it 'instantiates with a response hash and callbacks hash' do
      TweetStream::Response.new(nil, {}, {})
    end

    it 'instantiates with a block' do
      TweetStream::Response.new(nil, {}, {}) {}
    end
  end

  describe 'invoke_callback' do
    it 'instantiates'
  end

  describe 'to_class' do
    it 'returns a Response class' do
      resp = TweetStream::Response.new(nil, {:control => 'abc'}, {})
      resp.to_class('Control').should eq(TweetStream::ControlResponse)
    end
  end

  describe 'type' do
    it 'identifies the response type based on the response hash' do
      TweetStream::Response.new(nil, {:control => 'abc'}, {}).type.should eq('Control')
      TweetStream::Response.new(nil, {:event => 'abc'}, {}).type.should eq('Event')
    end
  end

end
