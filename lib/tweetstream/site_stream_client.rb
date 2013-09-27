require 'em-http'
require 'em-http/middleware/oauth'
require 'em-http/middleware/json_response'

module TweetStream
  class SiteStreamClient

    attr_accessor *Configuration::OAUTH_OPTIONS_KEYS

    def initialize(config_uri, oauth = {})
      @config_uri = config_uri

      options = TweetStream.oauth_options.merge(oauth)
      Configuration::OAUTH_OPTIONS_KEYS.each do |key|
        send("#{key}=", options[key])
      end

      EventMachine::HttpRequest.use EventMachine::Middleware::JSONResponse
    end

    def on_error(&block)
      if block_given?
        @on_error = block
        self
      else
        @on_error
      end
    end

    def info(&block)
      options = { :error_msg => 'Failed to retrieve SiteStream info.' }
      request(:get, info_path, options, &block)
    end

    def add_user(user_id, &block)
      options = {
                  :error_msg => 'Failed to add user to SiteStream',
                  :body => { 'user_id' => normalized_user_ids(user_id) }
                }

      request(:post, add_user_path, options, &block)
    end

    def remove_user(user_id, &block)
      options = {
                  :error_msg => 'Failed to remove user from SiteStream.',
                  :body => { 'user_id' => normalized_user_ids(user_id) }
                }

      request(:post, remove_user_path, options, &block)
    end

    def friends_ids(user_id, &block)
      options = { :error_msg => 'Failed to retrieve SiteStream friends ids.',
                  :body => { 'user_id' => user_id }
                }
      request(:post, friends_ids_path, options, &block)
    end

    private

    def connection
      return @conn if defined?(@conn)

      @conn = EventMachine::HttpRequest.new('https://sitestream.twitter.com/')
      @conn.use EventMachine::Middleware::OAuth, oauth_configuration
      @conn
    end

    def oauth_configuration
      {
        :consumer_key => consumer_key,
        :consumer_secret => consumer_secret,
        :access_token => oauth_token,
        :access_token_secret => oauth_token_secret
      }
    end

    def info_path
      @config_uri + '/info.json'
    end

    def add_user_path
      @config_uri + '/add_user.json'
    end

    def remove_user_path
      @config_uri + '/remove_user.json'
    end

    def friends_ids_path
      @config_uri + '/friends/ids.json'
    end

    def request(method, path, options, &block)
      error_msg = options.delete(:error_msg)

      http = connection.send(method, options.merge(:path => path))
      http.callback do
        if http.response_header.status == 200
          if block && block.kind_of?(Proc)
            if block.arity == 1
              block.call http.response
            else
              block.call
            end
          end
        else
          @on_error.call(error_msg) if @on_error && @on_error.kind_of?(Proc)
        end
      end
      http.errback do
        @on_error.call(error_msg) if @on_error && @on_error.kind_of?(Proc)
      end
    end

    def normalized_user_ids(user_id)
      if user_id.kind_of?(Array)
        user_id.join(',') 
      else
        user_id.to_s
      end
    end

  end
end
