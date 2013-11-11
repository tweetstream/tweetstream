require 'em-twitter'
require 'eventmachine'
require 'multi_json'
require 'twitter'
require 'forwardable'

require 'tweetstream/arguments'

module TweetStream
  # Provides simple access to the Twitter Streaming API (https://dev.twitter.com/docs/streaming-api)
  # for Ruby scripts that need to create a long connection to
  # Twitter for tracking and other purposes.
  #
  # Basic usage of the library is to call one of the provided
  # methods and provide a block that will perform actions on
  # a yielded Twitter::Tweet. For example:
  #
  #     TweetStream::Client.new.track('fail') do |status|
  #       puts "[#{status.user.screen_name}] #{status.text}"
  #     end
  #
  # For information about a daemonized TweetStream client,
  # view the TweetStream::Daemon class.
  class Client
    extend Forwardable

    OPTION_CALLBACKS = [:delete,
                        :scrub_geo,
                        :limit,
                        :error,
                        :enhance_your_calm,
                        :unauthorized,
                        :reconnect,
                        :inited,
                        :direct_message,
                        :timeline_status,
                        :anything,
                        :no_data_received,
                        :status_withheld,
                        :user_withheld].freeze unless defined?(OPTION_CALLBACKS)

    # @private
    attr_accessor *Configuration::VALID_OPTIONS_KEYS
    attr_accessor :options
    attr_reader :control_uri, :control, :stream

    def_delegators :@control, :add_user, :remove_user, :info, :friends_ids

    # Creates a new API
    def initialize(options={})
      self.options = options
      merged_options = TweetStream.options.merge(options)
      Configuration::VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", merged_options[key])
      end
      @control_uri = nil
      @control     = nil
      @callbacks   = {}
    end

    # Returns all public statuses. The Firehose is not a generally
    # available resource. Few applications require this level of access.
    # Creative use of a combination of other resources and various access
    # levels can satisfy nearly every application use case.
    def firehose(query_parameters = {}, &block)
      start('/1.1/statuses/firehose.json', query_parameters, &block)
    end

    # Returns all statuses containing http: and https:. The links stream is
    # not a generally available resource. Few applications require this level
    # of access. Creative use of a combination of other resources and various
    # access levels can satisfy nearly every application use case.
    def links(query_parameters = {}, &block)
      start('/1.1/statuses/links.json', query_parameters, &block)
    end

    # Returns all retweets. The retweet stream is not a generally available
    # resource. Few applications require this level of access. Creative
    # use of a combination of other resources and various access levels
    # can satisfy nearly every application use case. As of 9/11/2009,
    # the site-wide retweet feature has not yet launched,
    # so there are currently few, if any, retweets on this stream.
    def retweet(query_parameters = {}, &block)
      start('/1.1/statuses/retweet.json', query_parameters, &block)
    end

    # Returns a random sample of all public statuses. The default access level
    # provides a small proportion of the Firehose. The "Gardenhose" access
    # level provides a proportion more suitable for data mining and
    # research applications that desire a larger proportion to be statistically
    # significant sample.
    def sample(query_parameters = {}, &block)
      start('/1.1/statuses/sample.json', query_parameters, &block)
    end

    # Specify keywords to track. Queries are subject to Track Limitations,
    # described in Track Limiting and subject to access roles, described in
    # the statuses/filter method. Track keywords are case-insensitive logical
    # ORs. Terms are exact-matched, and also exact-matched ignoring
    # punctuation. Phrases, keywords with spaces, are not supported.
    # Keywords containing punctuation will only exact match tokens.
    # Query parameters may be passed as the last argument.
    def track(*keywords, &block)
      query = TweetStream::Arguments.new(keywords)
      filter(query.options.merge(:track => query), &block)
    end

    # Returns public statuses from or in reply to a set of users. Mentions
    # ("Hello @user!") and implicit replies ("@user Hello!" created without
    # pressing the reply "swoosh") are not matched. Requires integer user
    # IDs, not screen names. Query parameters may be passed as the last argument.
    def follow(*user_ids, &block)
      query = TweetStream::Arguments.new(user_ids)
      filter(query.options.merge(:follow => query), &block)
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
      query = TweetStream::Arguments.new(locations_map)
      filter(query.options.merge(:locations => query), &block)
    end

    # Make a call to the statuses/filter method of the Streaming API,
    # you may provide <tt>:follow</tt>, <tt>:track</tt> or both as options
    # to follow the tweets of specified users or track keywords. This
    # method is provided separately for cases when it would conserve the
    # number of HTTP connections to combine track and follow.
    def filter(query_params = {}, &block)
      start('/1.1/statuses/filter.json', query_params.merge(:method => :post), &block)
    end

    # Make a call to the userstream api for currently authenticated user
    def userstream(query_params = {}, &block)
      stream_params = { :host => "userstream.twitter.com" }
      query_params.merge!(:extra_stream_parameters => stream_params)
      start('/1.1/user.json', query_params, &block)
    end

    # Make a call to the userstream api
    def sitestream(user_ids = [], query_params = {}, &block)
      stream_params = { :host => "sitestream.twitter.com" }
      query_params.merge!({
        :method                  => :post,
        :follow                  => user_ids,
        :extra_stream_parameters => stream_params
      })
      query_params.merge!(:with => 'followings') if query_params.delete(:followings)
      start('/1.1/site.json', query_params, &block)
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
      on('delete', &block)
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
      on('scrub_geo', &block)
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
      on('limit', &block)
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
      on('error', &block)
    end

    # Set a Proc to be run when an HTTP status 401 is encountered while
    # connecting to Twitter. This could happen when system clock drift
    # has occured.
    #
    # If no block is given, it will return the currently set
    # unauthorized proc. When a block is given, the TweetStream::Client
    # object is returned to allow for chaining.
    def on_unauthorized(&block)
      on('unauthorized', &block)
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
      on('direct_message', &block)
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
      on('anything', &block)
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
      on('timeline_status', &block)
    end

    # Set a Proc to be run on reconnect.
    #
    #     @client = TweetStream::Client.new
    #     @client.on_reconnect do |timeout, retries|
    #       # Make note of the reconnection
    #     end
    #
    def on_reconnect(&block)
      on('reconnect', &block)
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
      on('inited', &block)
    end

    # Set a Proc to be run when no data is received from the server
    # and a stall occurs.  Twitter defines this to be 90 seconds.
    #
    #     @client = TweetStream::Client.new
    #     @client.on_no_data_received do
    #       # Make note of no data, possi
    #     end
    def on_no_data_received(&block)
      on('no_data_received', &block)
    end

    # Set a Proc to be run when enhance_your_calm signal is received.
    #
    #     @client = TweetStream::Client.new
    #     @client.on_enhance_your_calm do
    #       # do something, your account has been blocked
    #     end
    def on_enhance_your_calm(&block)
      on('enhance_your_calm', &block)
    end

    # Set a Proc to be run when a status_withheld message is received.
    #
    #     @client = TweetStream::Client.new
    #     @client.on_status_withheld do |status|
    #       # do something with the status
    #     end
    def on_status_withheld(&block)
      on('status_withheld', &block)
    end

    # Set a Proc to be run when a status_withheld message is received.
    #
    #     @client = TweetStream::Client.new
    #     @client.on_user_withheld do |status|
    #       # do something with the status
    #     end
    def on_user_withheld(&block)
      on('user_withheld', &block)
    end

    # Set a Proc to be run when a Site Stream friends list is received.
    #
    #     @client = TweetStream::Client.new
    #     @client.on_friends do |friends|
    #       # do something with the friends list
    #     end
    def on_friends(&block)
      on('friends', &block)
    end

    # Set a Proc to be run when a stall warning is received.
    #
    #     @client = TweetStream::Client.new
    #     @client.on_stall_warning do |warning|
    #       # do something with the friends list
    #     end
    def on_stall_warning(&block)
      on('stall_warning', &block)
    end

    # Set a Proc to be run on userstream events
    #
    #     @client = TweetStream::Client.new
    #     @client.on_event(:favorite) do |event|
    #       # do something with the status
    #     end
    def on_event(event, &block)
      on(event, &block)
    end

    # Set a Proc to be run when sitestream control is received
    #
    #     @client = TweetStream::Client.new
    #     @client.on_control do
    #       # do something with the status
    #     end
    def on_control(&block)
      on('control', &block)
    end

    def on(event, &block)
      if block_given?
        @callbacks[event.to_s] = block
        self
      else
        @callbacks[event.to_s]
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
    def connect(path, options = {}, &block)
      stream_parameters, callbacks = connection_options(path, options)

      @stream = EM::Twitter::Client.connect(stream_parameters)
      @stream.each do |item|
        begin
          hash = MultiJson.decode(item, :symbolize_keys => true)
        rescue MultiJson::DecodeError
          invoke_callback(callbacks['error'], "MultiJson::DecodeError occured in stream: #{item}")
          next
        end

        unless hash.is_a?(::Hash)
          invoke_callback(callbacks['error'], "Unexpected JSON object in stream: #{item}")
          next
        end

        Twitter.identity_map = false

        respond_to(hash, callbacks, &block)

        yield_message_to(callbacks['anything'], hash)
      end

      @stream.on_error do |message|
        invoke_callback(callbacks['error'], message)
      end

      @stream.on_unauthorized do
        invoke_callback(callbacks['unauthorized'])
      end

      @stream.on_enhance_your_calm do
        invoke_callback(callbacks['enhance_your_calm'])
      end

      @stream.on_reconnect do |timeout, retries|
        invoke_callback(callbacks['reconnect'], timeout, retries)
      end

      @stream.on_max_reconnects do |timeout, retries|
        raise TweetStream::ReconnectError.new(timeout, retries)
      end

      @stream.on_no_data_received do
        invoke_callback(callbacks['no_data_received'])
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

    def controllable?
      !!@control
    end

    protected

    def respond_to(hash, callbacks, &block)
      if hash[:control] && hash[:control][:control_uri]
        @control_uri = hash[:control][:control_uri]
        require 'tweetstream/site_stream_client'
        @control = TweetStream::SiteStreamClient.new(@control_uri, options)
        @control.on_error(&callbacks['error'])
        invoke_callback(callbacks['control'])
      elsif hash[:warning]
        invoke_callback(callbacks['stall_warning'], hash[:warning])
      elsif hash[:delete] && hash[:delete][:status]
        invoke_callback(callbacks['delete'], hash[:delete][:status][:id], hash[:delete][:status][:user_id])
      elsif hash[:scrub_geo] && hash[:scrub_geo][:up_to_status_id]
        invoke_callback(callbacks['scrub_geo'], hash[:scrub_geo][:up_to_status_id], hash[:scrub_geo][:user_id])
      elsif hash[:limit] && hash[:limit][:track]
        invoke_callback(callbacks['limit'], hash[:limit][:track])
      elsif hash[:direct_message]
        yield_message_to(callbacks['direct_message'], Twitter::DirectMessage.new(hash[:direct_message]))
      elsif hash[:status_withheld]
        invoke_callback(callbacks['status_withheld'], hash[:status_withheld])
      elsif hash[:user_withheld]
        invoke_callback(callbacks['user_withheld'], hash[:user_withheld])
      elsif hash[:event]
        invoke_callback(callbacks[hash[:event].to_s], hash)
      elsif hash[:friends]
        invoke_callback(callbacks['friends'], hash[:friends])
      elsif hash[:text] && hash[:user]
        @last_status = Twitter::Tweet.new(hash)
        yield_message_to(callbacks['timeline_status'], @last_status)

        yield_message_to(block, @last_status) if block_given?
      elsif hash[:for_user]
        yield_message_to(block, hash) if block_given?
      end
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
      if auth_method.to_s == 'basic'
        { :basic => {
            :username => username,
            :password => password
          }
        }
      else
        { :oauth => {
          :consumer_key => consumer_key,
          :consumer_secret => consumer_secret,
          :token => oauth_token,
          :token_secret => oauth_token_secret
        }
       }
      end
    end

    # A utility method used to invoke callback methods against the Client
    def invoke_callback(callback, *args)
      callback.call(*args) if callback
    end

    def yield_message_to(procedure, message)
      # Give the block the option to receive either one
      # or two arguments, depending on its arity.
      if procedure.is_a?(Proc)
        case procedure.arity
        when 1 then invoke_callback(procedure, message)
        when 2 then invoke_callback(procedure, message, self)
        end
      end
    end

    def connection_options(path, options)
      warn_if_callbacks(options)

      callbacks = @callbacks.dup
      OPTION_CALLBACKS.each do |callback|
        callbacks.merge(callback.to_s => options.delete(callback)) if options[callback]
      end

      inited_proc             = options.delete(:inited)                  || @callbacks['inited']
      extra_stream_parameters = options.delete(:extra_stream_parameters) || {}

      stream_params = {
        :path       => path,
        :method     => (options.delete(:method) || 'get').to_s.upcase,
        :user_agent => user_agent,
        :on_inited  => inited_proc,
        :params     => normalize_filter_parameters(options),
        :proxy      => proxy
      }.merge(extra_stream_parameters).merge(auth_params)

      [stream_params, callbacks]
    end

    def warn_if_callbacks(options={})
      if OPTION_CALLBACKS.select { |callback| options[callback] }.size > 0
        Kernel.warn("Passing callbacks via the options hash is deprecated and will be removed in TweetStream 3.0")
      end
    end
  end
end
