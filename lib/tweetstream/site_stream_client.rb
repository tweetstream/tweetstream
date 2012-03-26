require 'em-http'

module TweetStream
  class SiteStreamClient

    attr_accessor *Configuration::OAUTH_OPTIONS_KEYS

    def initialize(config_uri, oauth = {})
      options = TweetStream.oauth_options.merge(oauth)
      Configuration::OAUTH_OPTIONS_KEYS.each do |key|
        send("#{key}=", options[key])
      end
    end
  end
end