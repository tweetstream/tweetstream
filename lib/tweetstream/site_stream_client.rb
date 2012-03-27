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
      error_msg = 'Failed to retrieve SiteStream info.'

      http = connection.get(:path => info_path)
      http.callback do
        if http.response_header.status == 200
          block.call http.response if block && block.kind_of?(Proc)
        else
          @on_error.call(error_msg) if @on_error && @on_error.kind_of?(Proc)
        end
      end
      http.errback do
        @on_error.call(error_msg) if @on_error && @on_error.kind_of?(Proc)
      end
    end

    def add_user(user_id, &block)
      error_msg = 'Failed to add user to SiteStream'
      user_management(add_user_path, user_id, error_msg, &block)
    end

    def remove_user(user_id, &block)
      error_msg = 'Failed to remove user from SiteStream.'
      user_management(remove_user_path, user_id, error_msg, &block)
    end

    def friends_ids(user_id, &block)
      error_msg = 'Failed to retrieve SiteStream friends ids.'

      http = connection.post(:path => friends_ids_path, :body => { 'user_id' => user_id })
      http.callback do
        if http.response_header.status == 200
          block.call http.response if block && block.kind_of?(Proc)
        else
          @on_error.call(error_msg) if @on_error && @on_error.kind_of?(Proc)
        end
      end
      http.errback do
        @on_error.call(error_msg) if @on_error && @on_error.kind_of?(Proc)
      end
    end

    private

    def user_management(path, user_id, error_msg, &block)
      user_id = user_id.join(',') if user_id.kind_of?(Array)

      http = connection.post(:path => path, :body => { 'user_id' => user_id })
      http.callback do
        if http.response_header.status == 200
          block.call if block && block.kind_of?(Proc)
        else
          @on_error.call(error_msg) if @on_error && @on_error.kind_of?(Proc)
        end
      end
      http.errback do
        @on_error.call(error_msg) if @on_error && @on_error.kind_of?(Proc)
      end
    end

    def connection
      return @conn if @conn

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
  end
end