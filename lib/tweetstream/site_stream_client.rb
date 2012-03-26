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
      http = connection.get(:path => info_path)
      http.callback do
        if http.response_header.status == 200
          block.call http.response if block && block.kind_of?(Proc)
        else
          @on_error.call('Failed to retrieve SiteStream info.') if @on_error && @on_error.kind_of?(Proc)
        end
      end
      http.errback do
        @on_error.call('Failed to retrieve SiteStream info.') if @on_error && @on_error.kind_of?(Proc)
      end
    end

    private

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
  end
end