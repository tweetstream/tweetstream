$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'rubygems'
require 'tweetstream'

@oauth = { :consumer_key => YOUR_CONSUMER_TOKEN_HERE,
          :consumer_secret => YOUR_CONSUMER_SECRET_HERE,
          :access_key => YOUR_ACCESS_KEY_HERE,
          :access_secret => YOUR_ACCESS_SECRET_HERE }

client = TweetStream::Client.new(:oauth => @oauth)
client.user_stream { |status| p status }
