require 'uri'
require 'cgi'
require 'yajl'
require 'yajl/http_stream'

module TweetStream
  # Provides simple access to the Twitter Streaming API (http://apiwiki.twitter.com/Streaming-API-Documentation)
  # for Ruby scripts that need to create a long connection to
  # Twitter for tracking and other purposes.
  #
  # Basic usage of the library is to call one of the provided
  # methods and provide a block that will perform actions on
  # a yielded TweetStream::Status. For example:
  #
  #     TweetStream::Client.new('user','pass').track('fail') do |status|
  #       puts "[#{status.user.screen_name}] #{status.text}"
  #     end
  #
  # For information about a daemonized TweetStream client,
  # view the TweetStream::Daemon class.
  class Client
    attr_accessor :username, :password
    
    # Create a new client with the Twitter credentials
    # of the account you want to be using its API quota. 
    def initialize(user, pass)
      self.username = user
      self.password = pass
    end
   
    # Returns all public statuses. The Firehose is not a generally
    # available resource. Few applications require this level of access. 
    # Creative use of a combination of other resources and various access 
    # levels can satisfy nearly every application use case. 
    def firehose(query_parameters = {}, &block)
      start('statuses/firehose', query_parameters, &block)
    end
    
    # Returns all retweets. The retweet stream is not a generally available 
    # resource. Few applications require this level of access. Creative
    # use of a combination of other resources and various access levels
    # can satisfy nearly every application use case. As of 9/11/2009,
    # the site-wide retweet feature has not yet launched,
    # so there are currently few, if any, retweets on this stream.
    def retweet(query_parameters = {}, &block)
      start('statuses/retweet', query_parameters, &block)
    end
    
    # Returns a random sample of all public statuses. The default access level 
    # provides a small proportion of the Firehose. The "Gardenhose" access
    # level provides a proportion more suitable for data mining and
    # research applications that desire a larger proportion to be statistically
    # significant sample.
    def sample(query_parameters = {}, &block)
      start('statuses/sample', query_parameters, &block)
    end

    # Specify keywords to track. Queries are subject to Track Limitations, 
    # described in Track Limiting and subject to access roles, described in 
    # the statuses/filter method. Track keywords are case-insensitive logical 
    # ORs. Terms are exact-matched, and also exact-matched ignoring
    # punctuation. Phrases, keywords with spaces, are not supported. 
    # Keywords containing punctuation will only exact match tokens.
    # Query parameters may be passed as the last argument.
    def track(*keywords, &block)
      query_params = keywords.pop if keywords.last.is_a?(::Hash)
      query_params ||= {}
      start('statuses/filter', query_params.merge(:track => keywords.join(',')), &block)
    end
    
    # Returns public statuses from or in reply to a set of users. Mentions 
    # ("Hello @user!") and implicit replies ("@user Hello!" created without 
    # pressing the reply "swoosh") are not matched. Requires integer user
    # IDs, not screen names. Query parameters may be passed as the last argument.
    def follow(*user_ids, &block)
      query_params = user_ids.pop if user_ids.last.is_a?(::Hash)
      query_params ||= {}
      start('statuses/filter', query_params.merge(:follow => user_ids.join(',')), &block)
    end

    #:nodoc:
    def start(path, query_parameters = {}, &block)
      uri = build_uri(path, query_parameters)
      
      Yajl::HttpStream.get(uri, :symbolize_keys => true) do |hash|
        yield TweetStream::Status.new(hash)
      end
    end
 
    protected

    #:nodoc:
    def build_uri(path, query_parameters = {})
      URI.parse("http://#{self.username}:#{self.password}@stream.twitter.com/1/#{path}.json#{build_query_parameters(query_parameters)}")
    end

    #:nodoc:
    def build_query_parameters(query)
      return '' unless query && query.is_a?(::Hash) && query.size > 0
      pairs = []
      
      query.each_pair do |k,v|
        pairs << "#{k.to_s}=#{CGI.escape(v.to_s)}"
      end

      "?#{pairs.join('&')}"
    end
  end
end
