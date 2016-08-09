require "rubygems"
require "tweetstream"
require "em-http-request"
require "simple_oauth"
require "json"
require "uri"

# config oauth
OAUTH = {
 :consumer_key => "VIamDyoP5Jd3yGCL9DcYeqYKH",
 :consumer_secret => "kCJLLBQOW2b3eNNB96KWGH9Ok546faSW9iZB5nB3I2lyzbLCSI",
 :token => "756228730570235905-8Os53khet95jiaUBjLjM5LJbOJTp473",
 :token_secret => "GTi89RtQ9Kl0JWu2KMTslXXWwiGMG8iyZgASRi0mWzZ6o"
}
ACCOUNT_ID = OAUTH[:token].split("-").first.to_i

TweetStream.configure do |config|
 config.consumer_key       = OAUTH[:consumer_key]
 config.consumer_secret    = OAUTH[:consumer_secret]
 config.oauth_token        = OAUTH[:token]
 config.oauth_token_secret = OAUTH[:token_secret]
 config.auth_method = :oauth
end
