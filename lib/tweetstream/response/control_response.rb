module TweetStream
  class ControlResponse < Response

    def invoke
      @client.control_uri = @response_hash[:control][:control_uri]

      require 'tweetstream/site_stream_client'
      @client.control = TweetStream::SiteStreamClient.new(@control_uri, @client.options)
      @client.control.on_error(&@callbacks['error'])
    end

  end
end
