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
    k = name.sub(/[?!=]$/, '')

    if name =~ /=$/ && !args.empty?
      self[k] = args.first
    elsif self.include? k
      self[k]
    elsif self.include? k.to_sym
      self[k.to_sym]
    end
  end
end
