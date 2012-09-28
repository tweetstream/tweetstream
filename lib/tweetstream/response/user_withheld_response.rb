module TweetStream
  class UserWithheldResponse < Response

    def invoke
      invoke_callback(@callbacks['user_withheld'], @response_hash[:user_withheld])
    end

  end
end
