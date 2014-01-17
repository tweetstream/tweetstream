require 'tweetstream'

TweetStream.configure do |config|
  config.consumer_key       = 'abcdefghijklmnopqrstuvwxyz'
  config.consumer_secret    = '0123456789'
  config.oauth_token        = 'abcdefghijklmnopqrstuvwxyz'
  config.oauth_token_secret = '0123456789'
  config.auth_method        = :oauth
end

client = TweetStream::Client.new

client.on_error do |message|
  puts message
end

client.track('yankees') do |status|
  puts "#{status.text}"
end
