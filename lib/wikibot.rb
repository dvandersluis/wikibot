require 'class_ext'
require 'hash_ext'
require 'openhash'
require 'page'
require 'category'

require 'rubygems'
require 'curb'
require 'xmlsimple'
require 'deep_merge'

module WikiBot
  class CurbError < StandardError
    attr_accessor :curb
    def initialize(curb)
      @curb = curb 
    end
  end

  class APIError < StandardError
    attr_accessor :code, :info
    def initialize(code, info)
      @code = code
      @info = info
      end
  end

  class Bot
    class LoginError < StandardError; end

    @@version = "0.2.0"       # WikiBot version

    cattr_reader :version
    cattr_accessor :cookiejar # Filename where cookies will be stored

    attr_reader :config
    attr_reader :api_hits
    attr_accessor :page_writes
    attr_accessor :debug      # In debug mode, no writes will be made to the wiki
    attr_accessor :readonly   # Writes will not be made

    def initialize(username, password, options = {})
      @config = Hash.new
      @cookies = Hash.new
      @api_hits = 0
      @page_writes = 0

      api = options[:api] || "http://en.wikipedia.org/w/api.php"
      auto_login = options[:auto_login] || false
      @readonly = options[:readonly] || false
      @debug = options[:debug] || false

      @config = {
        :username   => username,
        :password   => password,
        :api        => api,
        :logged_in  => false
      }

      # Set up cURL:
      @curl = Curl::Easy.new do |c|
        c.headers["User-Agent"] = "Mozilla/5.0 Curb/Taf2/0.2.8 WikiBot/#{config[:username]}/#{@@version}"
        #c.enable_cookies        = true
        #c.cookiejar             = @@cookiejar
       end

      login if auto_login
    end

    def query_api(method, raw_data = {})
      url = @config[:api]

      raw_data[:format] = :xml if !(raw_data.include? :format and raw_data.include? 'format')

      @curl.headers["Cookie"] = @cookies.inject([]) do |memo, pair|
        key, val = pair
        memo.push(CGI::escape(key) + "=" + CGI::escape(val))
      end.join("; ") unless @cookies.nil?

      response_xml = {}

      while true
        if method == :post
          data = raw_data.to_post_fields
        elsif method == :get
          url = url.chomp("?") + "?" + raw_data.to_querystring
          data = nil
        end

        @curl.url = url
        @curl.headers["Expect"] = nil # MediaWiki will give a 417 error if Expect is set

        if @debug
          @curl.on_debug do |type, data|
             p data
          end
        end
        
        # If Set-Cookie headers are given in the response, set the cookies
        @curl.on_header do |data|
          header, text = data.split(":").map(&:strip)
          if header == "Set-Cookie"
            parts = text.split(";")
            cookie_name, cookie_value = parts[0].split("=")
            @cookies[cookie_name] = cookie_value
          end
          data.length
        end

        if data.nil? or (data.is_a? Array and data.empty?)
          @curl.send("http_#{method}".to_sym)
        else
          @curl.send("http_#{method}".to_sym, *data)
        end
        @api_hits += 1

        raise CurbError.new(@curl) unless @curl.response_code == 200
        
        xml = XmlSimple.xml_in(@curl.body_str, {'ForceArray' => false})
        raise APIError.new(xml['error']['code'], xml['error']['info']) if xml['error']

        response_xml.deep_merge! xml
        if xml['query-continue']
          raw_data.merge! xml['query-continue'][xml['query-continue'].keys.first]
        else
          break
        end
      end

      OpenHash.new(response_xml)
    end
    
    def login
      return if @config[:logged_in]

      data = {
        :action     => :login, 
        :lgname     => @config[:username],
        :lgpassword => @config[:password]
      }

      response = query_api(:post, data).login

      if response.result == "NeedToken"
        data = {
          :action     => :login, 
          :lgname     => @config[:username],
          :lgpassword => @config[:password],
          :lgtoken    => response.token
        }

        response = query_api(:post, data).login
      end

      raise LoginError, response.result unless response.result == "Success"

      @config[:cookieprefix] = response.cookieprefix 
      @config[:logged_in] = true
    end

    def logout
      return if !@config[:logged_in]

      query_api(:post, { :action => :logout })
      @config[:logged_in] = false
      @config[:edit_token] = nil
    end

    def edit_token(page = "Main Page")
      @config[:edit_token] ||= begin
        data = {
          :action     => :query, 
          :prop       => :info,
          :intoken    => :edit,
          :titles     => page 
        }

        query_api(:get, data).query.pages.page.edittoken
      end
    end

    # Get wiki stats
    def stats
      data = {
        :action       => :query,
        :meta         => :siteinfo,
        :siprop       => :statistics
      }

      query_api(:get, data).query.statistics
    end

    def page(name)
      WikiBot::Page.new(self, name)
    end

    def category(name)
      WikiBot::Category.new(self, name)
    end

    def format_date(date)
      # Formats a date into the Wikipedia format
      time = date.strftime("%H:%M")
      month = date.strftime("%B")
      "#{time}, #{date.day} #{month} #{date.year} (UTC)"
    end
  end
end
