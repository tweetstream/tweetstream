class TweetStream::Hash < ::Hash #:nodoc: all
  def initialize(other_hash = {})
    other_hash.keys.each do |key|
      value = other_hash[key]
      value = TweetStream::Hash.new(value) if value.is_a?(::Hash)
      self[key.to_sym] = value
    end
  end

  # This shim is necessary since method_missing won't be invoked for #id on
  # Ruby < 1.9
  def id
    if key?(:id)
      self[:id]
    else
      super
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
