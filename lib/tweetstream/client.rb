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
      filter(query_params.merge(:track => keywords), &block)
    end

    # Returns public statuses from or in reply to a set of users. Mentions 
    # ("Hello @user!") and implicit replies ("@user Hello!" created without 
    # pressing the reply "swoosh") are not matched. Requires integer user
    # IDs, not screen names. Query parameters may be passed as the last argument.
    def follow(*user_ids, &block)
      query_params = user_ids.pop if user_ids.last.is_a?(::Hash)
      query_params ||= {}
      filter(query_params.merge(:follow => user_ids), &block)
    end
    
    # Make a call to the statuses/filter method of the Streaming API,
    # you may provide <tt>:follow</tt>, <tt>:track</tt> or both as options
    # to follow the tweets of specified users or track keywords. This
    # method is provided separately for cases when it would conserve the
    # number of HTTP connections to combine track and follow.
    def filter(query_params = {}, &block)
      [:follow, :track].each do |param|
        if query_params[param].is_a?(Array)
          query_params[param] = query_params[param].collect{|q| q.to_s}.join(',')
        elsif query_params[param]
          query_params[param] = query_params[param].to_s
        end
      end
      start('statuses/filter', query_params.merge(:method => :post), &block)
    end

    # Set a Proc to be run when a deletion notice is received
    # from the Twitter stream. For example:
    #
    #     @client = TweetStream::Client.new('user','pass')
    #     @client.on_delete do |status_id, user_id|
    #       Tweet.delete(status_id)
    #     end
    #
    # Block must take two arguments: the status id and the user id.
    # If no block is given, it will return the currently set 
    # deletion proc. When a block is given, the TweetStream::Client
    # object is returned to allow for chaining.
    def on_delete(&block)
      if block_given?
        @on_delete = block
        self
      else
        @on_delete
      end
    end
    
    # Set a Proc to be run when a rate limit notice is received
    # from the Twitter stream. For example:
    #
    #     @client = TweetStream::Client.new('user','pass')
    #     @client.on_limit do |discarded_count|
    #       # Make note of discarded count
    #     end
    #
    # Block must take one argument: the number of discarded tweets.
    # If no block is given, it will return the currently set 
    # limit proc. When a block is given, the TweetStream::Client
    # object is returned to allow for chaining.
    def on_limit(&block)
      if block_given?
        @on_limit = block
        self
      else
        @on_limit
      end
    end
    
    def start(path, query_parameters = {}, &block) #:nodoc:
      method = query_parameters.delete(:method) || :get
      delete_proc = query_parameters.delete(:delete) || self.on_delete
      limit_proc = query_parameters.delete(:limit) || self.on_limit
      
      uri = method == :get ? build_uri(path, query_parameters) : build_uri(path)
      
      args = [uri]
      args << build_post_body(query_parameters) if method == :post
      args << {:symbolize_keys => true}

      @stream = Yajl::HttpStream.new

      @stream.send(method, *args) do |hash|
        if hash[:delete] && hash[:delete][:status]
          delete_proc.call(hash[:delete][:status][:id], hash[:delete][:status][:user_id]) if delete_proc.is_a?(Proc)
        elsif hash[:limit] && hash[:limit][:track]
          limit_proc.call(hash[:limit][:track]) if limit_proc.is_a?(Proc)
        elsif hash[:text] && hash[:user]
          @last_status = TweetStream::Status.new(hash)
          yield @last_status
        end
      end
    rescue TweetStream::Terminated
      return @last_status
    rescue Yajl::HttpStream::InvalidContentType
      raise TweetStream::ConnectionError, "There was an error connecting to the Twitter streaming service. Please check your credentials and the current status of the Streaming API."
    end
    
    # Terminate the currently running TweetStream.
    def self.stop
      raise TweetStream::Terminated
    end

    # Terminate the currently running TweetStream.
    def stop
      @stream.terminate unless @stream.nil?
    end
 
    protected

    def build_uri(path, query_parameters = {}) #:nodoc:
      URI.parse("http://#{URI.encode self.username}:#{URI.encode self.password}@stream.twitter.com/1/#{path}.json#{build_query_parameters(query_parameters)}")
    end

    def build_query_parameters(query)
      query.size > 0 ? "?#{build_post_body(query)}" : ''
    end
    
    def build_post_body(query) #:nodoc:
      return '' unless query && query.is_a?(::Hash) && query.size > 0
      pairs = []
      
      query.each_pair do |k,v|
        pairs << "#{k.to_s}=#{CGI.escape(v.to_s)}"
      end

      pairs.join('&')
    end
  end
end
