module TweetStream
  class TimelineStatusResponse < Response

    def invoke
      tweet = Twitter::Tweet.new(@response_hash)
      yield_message_to(@callbacks['timeline_status'], tweet)

      yield_message_to(@block, tweet) if @block && @block.is_a?(Proc)
    end

  end
end
