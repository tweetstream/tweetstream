module TweetStream
  class StatusWithheldResponse < Response

    def invoke
      invoke_callback(@callbacks['status_withheld'], @response_hash[:status_withheld])
    end

  end
end
