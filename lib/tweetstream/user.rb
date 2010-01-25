# A simple Hash wrapper that gives you method-based
# access to user properties returned by the streamer.
class TweetStream::User < TweetStream::Hash
  def id
    self[:id] || super
  end
end
