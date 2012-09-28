module TweetStream
  class LimitResponse < Response

    def invoke
      invoke_callback(@callbacks['limit'], @response_hash[:limit][:track])
    end

  end
end
