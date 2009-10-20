require 'tweetstream/client'
require 'tweetstream/hash'
require 'tweetstream/status'
require 'tweetstream/user'
require 'tweetstream/daemon'

module TweetStream
  class Terminated < ::StandardError; end
  class Error < ::StandardError; end
  class ConnectionError < TweetStream::Error; end
end