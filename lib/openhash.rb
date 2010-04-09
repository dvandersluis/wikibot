class OpenHash < Hash
  undef_method :id

  def initialize(hash = {})
    super()
    update(hash)
  end

  def [](key)
    h = super(key)
    h.is_a?(Hash) ? OpenHash.new(h) : h
  end

  # Allow hash properties to be referenced by dot notation
  def method_missing(name, *args)
    name = name.to_s
    if self.include? name
      self[name]
    elsif self.include? name.to_sym
      self[name.to_sym]
    end
  end
end
