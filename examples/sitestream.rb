require 'yajl'
require 'tweetstream'

TweetStream.configure do |config|
  config.consumer_key       = 'abcdefghijklmnopqrstuvwxyz'
  config.consumer_secret    = '0123456789'
  config.oauth_token        = 'abcdefghijklmnopqrstuvwxyz'
  config.oauth_token_secret = '0123456789'
  config.auth_method        = :oauth
end

EM.run do

  client = TweetStream::Client.new

  client.on_error do |error|
    puts error
  end

  client.sitestream([user_id], :followings => true) do |status|
    puts status.inspect
  end

  EM::Timer.new(60) do
    client.control.add_user(user_id_to_add)
    client.control.info { |i| puts i.inspect }
  end

  EM::Timer.new(75) do
    client.control.friends_ids(user_id) do |friends|
      puts friends.inspect
    end
  end

  EM::Timer.new(90) do
    client.control.remove_user(user_id_to_remove)
    client.control.info { |i| puts i.inspect }
  end

end
