require 'lib/hash_ext'
require 'lib/errors'
require 'lib/curl_ext'

require 'rubygems'
require 'curb'
require 'xmlsimple'

class WikiBot
  include WikiBotErrors

  attr_reader :config

  def initialize(username, password, api = "http://en.wikipedia.org/w/api.php", auto_login = false)
    @config = Hash.new

    @config = {
      :username   => username,
      :password   => password,
      :api        => api,
      :logged_in  => false
    }

    # Set up cURL:
    @curl = Curl::Easy.new do |curl|
      curl.headers["User-Agent"] = "Mozilla/5.0 Curb/Taf2/0.2.8 WikiBot/#{config[:username]}"
      curl.enable_cookies = true
    end

    login if auto_login
  end

  def login
    post_data = {
      :action     => :login, 
      :lgname     => @config[:username],
      :lgpassword => @config[:password],
      :format     => :xml,
    }

    @curl.do(:http_post, @config[:api], post_data.to_post_fields)
    res = XmlSimple.xml_in(@curl.body_str)

    raise LoginError, res['result'] unless res['result'] == "Success"

    @config[:logged_in] = true
  end

  def logout
    return if !@config[:logged_in]
    @curl.do(:http_post, @config[:api], Curl::PostField.content('action', 'logout'))
    @config[:logged_in] = false
  end
end
