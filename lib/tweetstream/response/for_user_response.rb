module TweetStream
  class ForUserResponse < Response

    def invoke
      yield_message_to(@block, @response_hash) if @block && @block.is_a?(Proc)
    end

  end
end
