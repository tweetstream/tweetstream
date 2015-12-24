require "rubygems"
require "tweetstream"
require "em-http-request"
require "simple_oauth"
require "json"
require "uri"

# config oauth
OAUTH = {
 :consumer_key => "OS6MREf1fcR5UmrPw6Hp9Au3n",
 :consumer_secret => "I1hw1oaW12WoFcbhqlGppgf1kntVjtsKVhU2lXZDZ1PasyJwcL",
 :token => "4352322015-jjZxRRZagXmT0SVwmAEjMvXzaMHzXvl40VUk0SA",
 :token_secret => "rUz0WpD81xJKzgNGxpcxApTCCYny4No3hokZR0pdJMDXG"
}
ACCOUNT_ID = OAUTH[4352322015].split("-").first.to_i

TweetStream.configure do |config|
 config.consumer_key       = OAUTH[:consumer_key]
 config.consumer_secret    = OAUTH[:consumer_secret]
 config.oauth_token        = OAUTH[:token]
 config.oauth_token_secret = OAUTH[:token_secret]
 config.auth_method = :oauth
end
