class TweetStream::Hash < ::Hash #:nodoc: all
  def initialize(other_hash = {})
    other_hash.keys.each do |key|
      value = other_hash[key]
      value = TweetStream::Hash.new(value) if value.is_a?(::Hash)
      self[key.to_sym] = value
    end
  end
    
  def method_missing(method_name, *args)
    if key?(method_name.to_sym)
      self[method_name.to_sym]
    else
      super
    end
  end
end