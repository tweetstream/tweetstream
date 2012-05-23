require 'yajl'
require 'tweetstream'

TweetStream.configure do |config|
  config.consumer_key = 'abcdefghijklmnopqrstuvwxyz'
  config.consumer_secret = '0123456789'
  config.oauth_token = 'abcdefghijklmnopqrstuvwxyz'
  config.oauth_token_secret = '0123456789'
  config.auth_method = :oauth
  config.parser   = :yajl
end

client = TweetStream::Client.new

client.on_error do |message|
  puts message
end

client.on_direct_message do |direct_message|
  puts direct_message.text
end

client.on_timeline_status  do |status|
  puts status.text
end

client.userstream
