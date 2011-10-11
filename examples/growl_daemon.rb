require 'rubygems'
require 'tweetstream'
require 'growl'

tracks = 'yankees'
puts "Starting a GrowlTweet to track: #{tracks}"

TweetStream.configure do |config|
  config.consumer_key = 'abcdefghijklmnopqrstuvwxyz'
  config.consumer_secret = '0123456789'
  config.oauth_token = 'abcdefghijklmnopqrstuvwxyz'
  config.oauth_token_secret = '0123456789'
  config.auth_method = :oauth
end

TweetStream::Daemon.new('tracker').track(tracks) do |status|
  Growl.notify status.text, :title => status.user.screen_name
end
