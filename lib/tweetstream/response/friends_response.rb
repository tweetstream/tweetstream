module TweetStream
  class FriendsResponse < Response

    def invoke
      invoke_callback(@callbacks['friends'], @response_hash[:friends])
    end

  end
end
