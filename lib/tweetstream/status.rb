# A simple Hash wrapper that gives you method-based
# access to the properties of a Twitter status.
class TweetStream::Status < TweetStream::Hash
  def initialize(hash)
    super
    self[:user] = TweetStream::User.new(self[:user])
  end
  
  def id
    self[:id] || super
  end
end
