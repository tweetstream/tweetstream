module TweetStream
  class EventResponse < Response

    def invoke
      invoke_callback(@callbacks[@response_hash[:event].to_s], @response_hash)
    end

  end
end
