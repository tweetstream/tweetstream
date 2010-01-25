require 'json' unless defined?(JSON)

module TweetStream
  module Parsers
    class JsonGem
      def self.decode(string)
        ::JSON.parse(string)
      end
    end
  end
end