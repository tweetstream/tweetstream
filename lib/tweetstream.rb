require 'tweetstream/configuration'
require 'tweetstream/client'
require 'tweetstream/hash'
require 'tweetstream/status'
require 'tweetstream/direct_message'
require 'tweetstream/site_stream_message'
require 'tweetstream/user'
require 'tweetstream/error'
require 'tweetstream/daemon'

module TweetStream
  extend Configuration

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
