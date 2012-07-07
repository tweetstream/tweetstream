require 'tweetstream/configuration'
require 'tweetstream/client'
require 'tweetstream/daemon'

module TweetStream
  extend Configuration

  class ReconnectError < StandardError
    attr_accessor :timeout, :retries
    def initialize(timeout, retries)
      self.timeout = timeout
      self.retries = retries
      super("Failed to reconnect after #{retries} tries.")
    end
  end

  class << self
    # Alias for TweetStream::Client.new
    #
    # @return [TweetStream::Client]
    def new(options={})
      TweetStream::Client.new(options)
    end

    # Delegate to TweetStream::Client
    def method_missing(method, *args, &block)
      return super unless new.respond_to?(method)
      new.send(method, *args, &block)
    end

    # Delegate to TweetStream::Client
    def respond_to?(method, include_private = false)
      new.respond_to?(method, include_private) || super(method, include_private)
    end
  end
end
