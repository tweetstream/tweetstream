require 'simplecov'
require 'tweetstream'
require 'tweetstream/site_stream_client'
require 'rspec'
require 'webmock/rspec'
require 'yajl'
require 'json'

def sample_tweets
  return @tweets if @tweets

  @tweets = []
  Yajl::Parser.parse(File.open(File.dirname(__FILE__) + '/data/statuses.json', 'r'), :symbolize_keys => true) do |hash|
    @tweets << hash
  end
  @tweets
end

def sample_direct_messages
  return @direct_messages if @direct_messages

  @direct_messages = []
  Yajl::Parser.parse(File.open(File.dirname(__FILE__) + '/data/direct_messages.json', 'r')) do |hash|
    @direct_messages << hash
  end
  @direct_messages
end

def fixture_path
  File.expand_path("../fixtures", __FILE__)
end

def fixture(file)
  File.new(fixture_path + '/' + file)
end