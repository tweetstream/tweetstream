class TweetStream::DirectMessage < TweetStream::Hash
  def initialize(hash)
    super
    self[:user] = self[:sender] = TweetStream::User.new(self[:sender])
  end
end
