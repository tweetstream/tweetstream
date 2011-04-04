require 'tweetstream/configuration'
require 'tweetstream/client'
require 'tweetstream/hash'
require 'tweetstream/status'
require 'tweetstream/user'
require 'tweetstream/daemon'

module TweetStream
  extend Configuration

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

  # Alias for TweetStream::Client.new
  #
  # @return [TweetStream::Client]
  def self.client(options={})
    TweetStream::Client.new(options)
  end

  # Delegate to TweetStream::Client
  def self.method_missing(method, *args, &block)
    return super unless client.respond_to?(method)
    client.send(method, *args, &block)
  end

  # Delegate to TweetStream::Client
  def self.respond_to?(method)
    client.respond_to?(method) || super
  end
end