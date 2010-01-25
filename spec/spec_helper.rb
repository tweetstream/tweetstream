$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'tweetstream'
require 'spec'
require 'spec/autorun'
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

Spec::Runner.configure do |config|
  
end
