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
require 'active_support/ordered_hash'
require 'active_support/json'

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
