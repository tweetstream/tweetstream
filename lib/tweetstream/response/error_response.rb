module TweetStream
  class ErrorResponse < Response

    def initialize(callback, *args)
      @callback = callback
      @arguments = args
    end

    def invoke
      invoke_callback(@callback, *@arguments)
    end

  end
end
