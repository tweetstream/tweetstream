require 'json/pure' unless defined?(::JSON)

module TweetStream
  module Parsers
    class JsonPure
      def self.decode(string)
        ::JSON.parse(string)
      end
    end
  end
end