require 'yajl' unless defined?(Yajl)

module TweetStream
  module Parsers
    class Yajl
      def self.decode(string)
        ::Yajl::Parser.new(:symbolize_keys => true).parse(string)
      end
    end
  end
end