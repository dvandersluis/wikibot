require 'cgi'

class Hash
  def to_post_fields
    inject([]) do |memo, pair|
      key, val = pair
      memo.push Curl::PostField.content(key.to_s, val.to_s)
    end
  end

  def to_querystring
    inject([]) do |memo, pair|
      key, val = pair
      memo.push "#{CGI::escape(key.to_s)}=#{CGI::escape(val.to_s)}"
    end.join("&")
  end
end
