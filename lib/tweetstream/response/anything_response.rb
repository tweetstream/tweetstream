module TweetStream
  class AnythingResponse < Response

    def invoke
      yield_message_to(@callbacks['anything'], @response_hash)
    end

  end
end
