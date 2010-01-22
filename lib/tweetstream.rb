require 'tweetstream/client'
require 'tweetstream/hash'
require 'tweetstream/status'
require 'tweetstream/user'
require 'tweetstream/daemon'

module TweetStream
  class Terminated < ::StandardError; end
  class Error < ::StandardError; end
  class ConnectionError < TweetStream::Error; end
  # A ReconnectError is raised when the maximum number of retries has
  # failed to re-establish a connection.
  class ReconnectError < StandardError
    attr_accessor :timeout, :retries
    def initialize(timeout, retries)
      self.timeout = timeout
      self.retries = retries
      super("Failed to reconnect after #{retries} tries.")
    end
  end
end