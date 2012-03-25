# A simple Hash wrapper that gives you method-based
# access to the properties of a Twitter status.
class TweetStream::SiteStreamMessage < TweetStream::Hash
  def initialize(hash)
    super
  end
end
