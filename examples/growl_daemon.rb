require 'rubygems'
require 'tweetstream'
require 'ruby-growl'

if args_start = ARGV.index('--')
  username, password = ARGV[args_start + 1].split(':')
  tracks = ARGV[args_start + 2 .. -1]
  puts "Starting a GrowlTweet to track: #{tracks.inspect}"
end

TweetStream.configure do |config|
  config.consumer_key = 'abcdefghijklmnopqrstuvwxyz'
  config.consumer_secret = '0123456789'
  config.oauth_token = 'abcdefghijklmnopqrstuvwxyz'
  config.oauth_token_secret = '0123456789'
  config.auth_method = :oauth
end

TweetStream::Daemon.new('tracker').track(*tracks) do |status|
  g = Growl.new 'localhost', 'growltweet', ['tweet']
  g.notify 'tweet', status.user.screen_name, status.text
end
