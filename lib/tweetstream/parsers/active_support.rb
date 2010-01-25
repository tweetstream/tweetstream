require 'active_support/json' unless defined?(::ActiveSupport::JSON)

module TweetStream
  module Parsers
    class ActiveSupport
      def self.decode(string)
        ::ActiveSupport::JSON.decode(string)
      end
    end
  end
end