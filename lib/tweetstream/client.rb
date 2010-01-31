require 'uri'
require 'cgi'
require 'eventmachine'
require 'twitter/json_stream'
require 'json'

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
    attr_reader :parser

    # Set the JSON Parser for this client. Acceptable options are:
    #
    # <tt>:json_gem</tt>:: Parse using the JSON gem.
    # <tt>:json_pure</tt>:: Parse using the pure-ruby implementation of the JSON gem.
    # <tt>:active_support</tt>:: Parse using ActiveSupport::JSON.decode
    # <tt>:yajl</tt>:: Parse using <tt>yajl-ruby</tt>.
    #
    # You may also pass a class that will return a hash with symbolized
    # keys when <tt>YourClass.parse</tt> is called with a JSON string.
    def parser=(parser)
      @parser = parser_from(parser)
    end
    
    # Create a new client with the Twitter credentials
    # of the account you want to be using its API quota.
    # You may also set the JSON parsing library as specified
    # in the #parser= setter.
    def initialize(user, pass, parser = :json_gem)
      self.username = user
      self.password = pass
      self.parser = parser
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
    
    # Set a Proc to be run when an HTTP error is encountered in the
    # processing of the stream. Note that TweetStream will automatically
    # try to reconnect, this is for reference only. Don't panic!
    #
    #     @client = TweetStream::Client.new('user','pass')
    #     @client.on_error do |message|
    #       # Make note of error message
    #     end
    #
    # Block must take one argument: the error message.
    # If no block is given, it will return the currently set 
    # error proc. When a block is given, the TweetStream::Client
    # object is returned to allow for chaining.
    def on_error(&block)
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
      error_proc = query_parameters.delete(:error) || self.on_error
      
      uri = method == :get ? build_uri(path, query_parameters) : build_uri(path)
      
      EventMachine::run {
        @stream = Twitter::JSONStream.connect(
          :path => uri,
          :auth => "#{URI.encode self.username}:#{URI.encode self.password}",
          :method => method.to_s.upcase,
          :content => (method == :post ? build_post_body(query_parameters) : ''),
          :user_agent => 'TweetStream'
        )
        
        @stream.each_item do |item|
          hash = TweetStream::Hash.new(@parser.decode(item)) # @parser.parse(item)
          
          if hash[:delete] && hash[:delete][:status]
            delete_proc.call(hash[:delete][:status][:id], hash[:delete][:status][:user_id]) if delete_proc.is_a?(Proc)
          elsif hash[:limit] && hash[:limit][:track]
            limit_proc.call(hash[:limit][:track]) if limit_proc.is_a?(Proc)
          elsif hash[:text] && hash[:user]
            @last_status = TweetStream::Status.new(hash)
            
            # Give the block the option to receive either one
            # or two arguments, depending on its arity.
            case block.arity
              when 1
                yield @last_status
              when 2
                yield @last_status, self
            end
          end
        end
        
        @stream.on_error do |message|
          error_proc.call(message) if error_proc.is_a?(Proc)
        end
        
        @stream.on_max_reconnects do |timeout, retries|
          raise TweetStream::ReconnectError.new(timeout, retries)
        end
      }
    end
    
    # Terminate the currently running TweetStream.
    def stop
      EventMachine.stop_event_loop
      @last_status
    end
 
    protected

    def parser_from(parser)
      case parser
        when Class
          parser
        when Symbol
          require "tweetstream/parsers/#{parser.to_s}"
          eval("TweetStream::Parsers::#{parser.to_s.split('_').map{|s| s.capitalize}.join('')}")
      end
    end
    
    def build_uri(path, query_parameters = {}) #:nodoc:
      URI.parse("/1/#{path}.json#{build_query_parameters(query_parameters)}")
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
