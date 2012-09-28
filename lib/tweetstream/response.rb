module TweetStream
  class Response
    def initialize(client, hash, callbacks, &block)
      @client = client
      @response_hash = hash
      @callbacks = callbacks
      @block = block
    end

    def invoke
      to_class(type).new(@client, @response_hash, @callbacks, &@block).invoke
    end

    def to_class(type)
      TweetStream.const_get("#{type}Response")
    end

    def type
      response_keys = @response_hash.keys
      case
      when response_keys.include?(:control) then 'Control'
      when response_keys.include?(:delete) then 'Delete'
      when response_keys.include?(:direct_message) then 'DirectMessage'
      when response_keys.include?(:event) then 'Event'
      when response_keys.include?(:for_user) then 'ForUser'
      when response_keys.include?(:friends) then 'Friends'
      when response_keys.include?(:limit) then 'Limit'
      when response_keys.include?(:scrub_geo) then 'ScrubGeo'
      when response_keys.include?(:status_withheld) then 'StatusWithheld'
      when response_keys.include?(:user_withheld) then 'UserWithheld'
      when response_keys.include?(:text) then 'TimelineStatus'
      else 'Anything'
      end
    end

    private

    # A utility method used to invoke callback methods against the Client
    def invoke_callback(callback, *args)
      callback.call(*args) if callback
    end

    def yield_message_to(procedure, message)
      # Give the block the option to receive either one
      # or two arguments, depending on its arity.
      if procedure.is_a?(Proc)
        case procedure.arity
        when 1 then invoke_callback(procedure, message)
        when 2 then invoke_callback(procedure, message, @client)
        end
      end
    end
  end
end

require 'tweetstream/response/anything_response'
require 'tweetstream/response/control_response'
require 'tweetstream/response/delete_response'
require 'tweetstream/response/direct_message_response'
require 'tweetstream/response/event_response'
require 'tweetstream/response/for_user_response'
require 'tweetstream/response/friends_response'
require 'tweetstream/response/limit_response'
require 'tweetstream/response/scrub_geo_response'
require 'tweetstream/response/status_withheld_response'
require 'tweetstream/response/timeline_status_response'
require 'tweetstream/response/user_withheld_response'
