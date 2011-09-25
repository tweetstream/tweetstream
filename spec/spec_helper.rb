require 'simplecov'
SimpleCov.start do
  add_group 'Tweetstream', 'lib/tweetstream'
  add_group 'Specs', 'spec'
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'tweetstream'
require 'rspec'
require 'rspec/autorun'
require 'yajl'
require 'json'

def sample_tweets
  if @tweets
    @tweets
  else
    @tweets = []
    Yajl::Parser.parse(File.open(File.dirname(__FILE__) + '/data/statuses.json', 'r'), :symbolize_keys => true) do |hash|
      @tweets << hash
    end
    @tweets
  end
end

def sample_direct_messages
  return @direct_messages if @direct_messages

  @direct_messages = []
  Yajl::Parser.parse(File.open(File.dirname(__FILE__) + '/data/direct_messages.json', 'r')) do |hash|
    @direct_messages << hash
  end
  @direct_messages
end
