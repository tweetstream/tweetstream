module TweetStream
  class DirectMessageResponse < Response

    def invoke
      yield_message_to(@callbacks['direct_message'], Twitter::DirectMessage.new(@response_hash[:direct_message]))
    end

  end
end
