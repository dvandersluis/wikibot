class Hash
  def to_post_fields
    inject([]) do |memo, pair|
      key, val = pair
      memo.push Curl::PostField.content(key.to_s, val.to_s)
    end
  end
end
