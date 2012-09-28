module TweetStream
  class DeleteResponse < Response

    def invoke
      invoke_callback(@callbacks['delete'], @response_hash[:delete][:status][:id], @response_hash[:delete][:status][:user_id])
    end

  end
end
