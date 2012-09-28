module TweetStream
  class ScrubGeoResponse < Response

    def invoke
      invoke_callback(@callbacks['scrub_geo'], @response_hash[:scrub_geo][:up_to_status_id], @response_hash[:scrub_geo][:user_id])
    end

  end
end
