require 'cgi'
require 'eventmachine'
require 'multi_json'
require 'twitter'
require 'em-twitter'
require 'uri'

module TweetStream
  # Provides simple access to the Twitter Streaming API (http://apiwiki.twitter.com/Streaming-API-Documentation)
  # for Ruby scripts that need to create a long connection to
  # Twitter for tracking and other purposes.
  #
  # Basic usage of the library is to call one of the provided
  # methods and provide a block that will perform actions on
  # a yielded Twitter::Status. For example:
  #
  #     TweetStream::Client.new.track('fail') do |status|
  #       puts "[#{status.user.screen_name}] #{status.text}"
  #     end
  #
  # For information about a daemonized TweetStream client,
  # view the TweetStream::Daemon class.
  class Client

    # @private
    attr_accessor *Configuration::VALID_OPTIONS_KEYS
    attr_accessor :options
    attr_reader :control_uri, :control, :stream

    # Creates a new API
    def initialize(options={})
      self.options = options
      merged_options = TweetStream.options.merge(options)
      Configuration::VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", merged_options[key])
      end
    end

    # Returns all public statuses. The Firehose is not a generally
    # available resource. Few applications require this level of access.
    # Creative use of a combination of other resources and various access
    # levels can satisfy nearly every application use case.
    def firehose(query_parameters = {}, &block)
      start('statuses/firehose', query_parameters, &block)
    end

    # Returns all statuses containing http: and https:. The links stream is
    # not a generally available resource. Few applications require this level
    # of access. Creative use of a combination of other resources and various
    # access levels can satisfy nearly every application use case.
    def links(query_parameters = {}, &block)
      start('statuses/links', query_parameters, &block)
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

    # Specifies a set of bounding boxes to track. Only tweets that are both created
    # using the Geotagging API and are placed from within a tracked bounding box will
    # be included in the stream – the user’s location field is not used to filter tweets
    # (e.g. if a user has their location set to “San Francisco”, but the tweet was not created
    # using the Geotagging API and has no geo element, it will not be included in the stream).
    # Bounding boxes are specified as a comma separate list of longitude/latitude pairs, with
    # the first pair denoting the southwest corner of the box
    # longitude/latitude pairs, separated by commas. The first pair specifies the southwest corner of the box.
    def locations(*locations_map, &block)
      query_params = locations_map.pop if locations_map.last.is_a?(::Hash)
      query_params ||= {}
      filter(query_params.merge(:locations => locations_map), &block)
    end

    # Make a call to the statuses/filter method of the Streaming API,
    # you may provide <tt>:follow</tt>, <tt>:track</tt> or both as options
    # to follow the tweets of specified users or track keywords. This
    # method is provided separately for cases when it would conserve the
    # number of HTTP connections to combine track and follow.
    def filter(query_params = {}, &block)
      start('statuses/filter', query_params.merge(:method => :post), &block)
    end

    # Make a call to the userstream api for currently authenticated user
    def userstream(&block)
      stream_params = { :host => "userstream.twitter.com", :path => "/2/user.json" }
      start('', :extra_stream_parameters => stream_params, &block)
    end

    # Make a call to the userstream api
    def sitestream(user_ids = [], query_params = {}, &block)
      stream_params = { :host => "sitestream.twitter.com", :path => '/2b/site.json' }
      sitestream_params = {
        :method => :post,
        :follow => user_ids,
        :extra_stream_parameters => stream_params
      }
      sitestream_params.merge!(:with => 'followings') if query_params[:followings]
      start('', sitestream_params, &block)
    end

    # Set a Proc to be run when a deletion notice is received
    # from the Twitter stream. For example:
    #
    #     @client = TweetStream::Client.new
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

    # Set a Proc to be run when a scrub_geo notice is received
    # from the Twitter stream. For example:
    #
    #     @client = TweetStream::Client.new
    #     @client.on_scrub_geo do |up_to_status_id, user_id|
    #       Tweet.where(:status_id <= up_to_status_id)
    #     end
    #
    # Block must take two arguments: the upper status id and the user id.
    # If no block is given, it will return the currently set
    # scrub_geo proc. When a block is given, the TweetStream::Client
    # object is returned to allow for chaining.
    def on_scrub_geo(&block)
      if block_given?
        @on_scrub_geo = block
        self
      else
        @on_scrub_geo
      end
    end

    # Set a Proc to be run when a rate limit notice is received
    # from the Twitter stream. For example:
    #
    #     @client = TweetStream::Client.new
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
    #     @client = TweetStream::Client.new
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
        @on_error = block
        self
      else
        @on_error
      end
    end

    # Set a Proc to be run when an HTTP status 401 is encountered while
    # connecting to Twitter. This could happen when system clock drift
    # has occured.
    #
    # If no block is given, it will return the currently set
    # unauthorized proc. When a block is given, the TweetStream::Client
    # object is returned to allow for chaining.
    def on_unauthorized(&block)
      if block_given?
        @on_unauthorized = block
        self
      else
        @on_error
      end
    end

    # Set a Proc to be run when a direct message is encountered in the
    # processing of the stream.
    #
    #     @client = TweetStream::Client.new
    #     @client.on_direct_message do |direct_message|
    #       # do something with the direct message
    #     end
    #
    # Block must take one argument: the direct message.
    # If no block is given, it will return the currently set
    # direct message proc. When a block is given, the TweetStream::Client
    # object is returned to allow for chaining.
    def on_direct_message(&block)
      if block_given?
        @on_direct_message = block
        self
      else
        @on_direct_message
      end
    end

    # Set a Proc to be run whenever anything is encountered in the
    # processing of the stream.
    #
    #     @client = TweetStream::Client.new
    #     @client.on_anything do |status|
    #       # do something with the status
    #     end
    #
    # Block can take one or two arguments. |status (, client)|
    # If no block is given, it will return the currently set
    # timeline status proc. When a block is given, the TweetStream::Client
    # object is returned to allow for chaining.
    def on_anything(&block)
      if block_given?
        @on_anything = block
        self
      else
        @on_anything
      end
    end

    # Set a Proc to be run when a regular timeline message is encountered in the
    # processing of the stream.
    #
    #     @client = TweetStream::Client.new
    #     @client.on_timeline_status do |status|
    #       # do something with the status
    #     end
    #
    # Block can take one or two arguments. |status (, client)|
    # If no block is given, it will return the currently set
    # timeline status proc. When a block is given, the TweetStream::Client
    # object is returned to allow for chaining.
    def on_timeline_status(&block)
      if block_given?
        @on_timeline_status = block
        self
      else
        @on_timeline_status
      end
    end

    # Set a Proc to be run on reconnect.
    #
    #     @client = TweetStream::Client.new
    #     @client.on_reconnect do |timeout, retries|
    #       # Make note of the reconnection
    #     end
    #
    def on_reconnect(&block)
      if block_given?
        @on_reconnect = block
        self
      else
        @on_reconnect
      end
    end

    # Set a Proc to be run when connection established.
    # Called in EventMachine::Connection#post_init
    #
    #     @client = TweetStream::Client.new
    #     @client.on_inited do
    #       puts 'Connected...'
    #     end
    #
    def on_inited(&block)
      if block_given?
        @on_inited = block
        self
      else
        @on_inited
      end
    end

    # Set a Proc to be run when no data is received from the server
    # and a stall occurs.  Twitter defines this to be 90 seconds.
    #
    #     @client = TweetStream::Client.new
    #     @client.on_no_data do
    #       # Make note of no data, possi
    #     end
    def on_no_data_received(&block)
      if block_given?
        @on_no_data = block
        self
      else
        @on_no_data
      end
    end

    # connect to twitter while starting a new EventMachine run loop
    def start(path, query_parameters = {}, &block)
      if EventMachine.reactor_running?
        connect(path, query_parameters, &block)
      else
        EventMachine.epoll
        EventMachine.kqueue

        EventMachine::run do
          connect(path, query_parameters, &block)
        end
      end
    end

    # connect to twitter without starting a new EventMachine run loop
    def connect(path, query_parameters = {}, &block)
      method = query_parameters.delete(:method) || :get
      delete_proc = query_parameters.delete(:delete) || self.on_delete
      scrub_geo_proc = query_parameters.delete(:scrub_geo) || self.on_scrub_geo
      limit_proc = query_parameters.delete(:limit) || self.on_limit
      error_proc = query_parameters.delete(:error) || self.on_error
      unauthorized_proc = query_parameters.delete(:unauthorized) || self.on_unauthorized
      reconnect_proc = query_parameters.delete(:reconnect) || self.on_reconnect
      inited_proc = query_parameters.delete(:inited) || self.on_inited
      direct_message_proc = query_parameters.delete(:direct_message) || self.on_direct_message
      timeline_status_proc = query_parameters.delete(:timeline_status) || self.on_timeline_status
      anything_proc = query_parameters.delete(:anything) || self.on_anything
      no_data_proc = query_parameters.delete(:no_data_received) || self.on_no_data_received

      params = normalize_filter_parameters(query_parameters)

      extra_stream_parameters = query_parameters.delete(:extra_stream_parameters) || {}

      uri = method == :get ? build_uri(path, params) : build_uri(path)

      stream_params = {
        :path => uri,
        :method => method.to_s.upcase,
        :user_agent => user_agent,
        :on_inited => inited_proc,
        :params => params
      }.merge(extra_stream_parameters).merge(auth_params)

      @stream = EM::Twitter::Client.connect(stream_params)
      @stream.each do |item|
        begin
          hash = MultiJson.decode(item)
        rescue MultiJson::DecodeError
          error_proc.call("MultiJson::DecodeError occured in stream: #{item}") if error_proc.is_a?(Proc)
          next
        end

        unless hash.is_a?(::Hash)
          error_proc.call("Unexpected JSON object in stream: #{item}") if error_proc.is_a?(Proc)
          next
        end

        if hash['control'] && hash['control']['control_uri']
          @control_uri = hash['control']['control_uri']
          require 'tweetstream/site_stream_client'
          @control = TweetStream::SiteStreamClient.new(@control_uri, options)
          @control.on_error(&self.on_error)
        elsif hash['delete'] && hash['delete']['status']
          delete_proc.call(hash['delete']['status']['id'], hash['delete']['status']['user_id']) if delete_proc.is_a?(Proc)
        elsif hash['scrub_geo'] && hash['scrub_geo']['up_to_status_id']
          scrub_geo_proc.call(hash['scrub_geo']['up_to_status_id'], hash['scrub_geo']['user_id']) if scrub_geo_proc.is_a?(Proc)
        elsif hash['limit'] && hash['limit']['track']
          limit_proc.call(hash['limit']['track']) if limit_proc.is_a?(Proc)
        elsif hash['direct_message']
          yield_message_to direct_message_proc, Twitter::DirectMessage.new(hash['direct_message'])
        elsif hash['text'] && hash['user']
          @last_status = Twitter::Status.new(hash)
          yield_message_to timeline_status_proc, @last_status

          if block_given?
            # Give the block the option to receive either one
            # or two arguments, depending on its arity.
            case block.arity
              when 1
                yield @last_status
              when 2
                yield @last_status, self
            end
          end
        elsif hash['for_user']
          @message = hash

          if block_given?
            # Give the block the option to receive either one
            # or two arguments, depending on its arity.
            case block.arity
            when 1
              yield @message
            when 2
              yield @message, self
            end
          end
        end

        yield_message_to anything_proc, hash
      end

      @stream.on_error do |message|
        error_proc.call(message) if error_proc.is_a?(Proc)
      end

      @stream.on_unauthorized do
        unauthorized_proc.call if unauthorized_proc.is_a?(Proc)
      end

      @stream.on_reconnect do |timeout, retries|
        reconnect_proc.call(timeout, retries) if reconnect_proc.is_a?(Proc)
      end

      @stream.on_max_reconnects do |timeout, retries|
        raise TweetStream::ReconnectError.new(timeout, retries)
      end

      @stream.on_no_data_received do
        no_data_proc.call if no_data_proc.is_a?(Proc)
      end

      @stream
    end

    # Terminate the currently running TweetStream and close EventMachine loop
    def stop
      EventMachine.stop_event_loop
      @last_status
    end

    # Close the connection to twitter without closing the eventmachine loop
    def close_connection
      @stream.close_connection if @stream
    end

    def stop_stream
      @stream.stop if @stream
    end

    protected

    def build_uri(path, query_parameters = {}) #:nodoc:
      URI.parse("/1/#{path}.json#{build_query_parameters(query_parameters)}")
    end

    def build_query_parameters(query)
      query.size > 0 ? "?#{build_post_body(query)}" : ''
    end

    def build_post_body(query) #:nodoc:
      return '' unless query && query.is_a?(::Hash) && query.size > 0

      query.map do |k, v|
        v = v.flatten.collect { |q| q.to_s }.join(',') if v.is_a?(Array)
        "#{k.to_s}=#{CGI.escape(v.to_s)}"
      end.join('&')
    end

    def normalize_filter_parameters(query_parameters = {})
      [:follow, :track, :locations].each do |param|
        if query_parameters[param].kind_of?(Array)
          query_parameters[param] = query_parameters[param].flatten.collect { |q| q.to_s }.join(',')
        elsif query_parameters[param]
          query_parameters[param] = query_parameters[param].to_s
        end
      end
      query_parameters
    end

    def auth_params
      if auth_method == :basic
        { :basic => basic_auth_params }
      else
        { :oauth => oauth_params }
      end
    end

    def basic_auth_params
      {
        :username => username,
        :password => password
      }
    end

    def oauth_params
      {
        :consumer_key => consumer_key,
        :consumer_secret => consumer_secret,
        :token => oauth_token,
        :token_secret => oauth_token_secret
      }
    end

    def yield_message_to(procedure, message)
      if procedure.is_a?(Proc)
        case procedure.arity
          when 1
            procedure.call(message)
          when 2
            procedure.call(message, self)
        end
      end
    end
  end
end
