require 'multi_json'
require 'tweetstream/version'

module TweetStream
  # Defines constants and methods related to configuration
  module Configuration
    # An array of valid keys in the options hash when configuring TweetStream.
    VALID_OPTIONS_KEYS = [
      :parser,
      :username,
      :password,
      :user_agent].freeze

    # The parser that will be used to connect if none is set
    DEFAULT_PARSER = MultiJson.default_engine

    # By default, don't set a username
    DEFAULT_USERNAME = nil

    # By default, don't set a password
    DEFAULT_PASSWORD = nil

    # The user agent that will be sent to the API endpoint if none is set
    DEFAULT_USER_AGENT = "TweetStream Ruby Gem #{TweetStream::VERSION}".freeze

    # @private
    attr_accessor *VALID_OPTIONS_KEYS

    # When this module is extended, set all configuration options to their default values
    def self.extended(base)
      base.reset
    end

    # Convenience method to allow configuration options to be set in a block
    def configure
      yield self
    end

    # Create a hash of options and their values
    def options
      Hash[VALID_OPTIONS_KEYS.map {|key| [key, send(key)] }]
    end

    # Reset all configuration options to defaults
    def reset
      self.parser             = DEFAULT_PARSER
      self.username           = DEFAULT_USERNAME
      self.password           = DEFAULT_PASSWORD
      self.user_agent         = DEFAULT_USER_AGENT
      self
    end
  end
end
