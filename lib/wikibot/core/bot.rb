require 'rubygems'
require 'curb'
require 'xmlsimple'
require 'deep_merge'
require 'zlib'

module WikiBot
  class Bot
    class LoginError < StandardError; end

    attr_reader :config
    attr_reader :api_hits       # How many times the API was queried
    attr_accessor :page_writes  # How many write operations were performed
    attr_accessor :debug        # In debug mode, no writes will be made to the wiki
    attr_accessor :readonly     # Writes will not be made

    def initialize(username, password, options = {})
      @cookies = OpenHash.new
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
      }.to_openhash

      # Set up cURL:
      @curl = Curl::Easy.new do |c|
        c.headers["User-Agent"] = self.user_agent
        c.headers["Accept-Encoding"] = "gzip" # Request gzip-encoded content from MediaWiki
       end

      login if auto_login
    end

    def version
      # Specifies the client bot's version
      raise NotImplementedError
    end

    def user_agent
      "#{@config.username}/#{self.version} WikiBot/#{WikiBot::VERSION} (https://github.com/dvandersluis/wikibot)"
    end

    def query_api(method, raw_data = {})
      # Send a query to the API and handle the response
      url = @config.api
      raw_data = raw_data.to_openhash

      raw_data[:format] = :xml if raw_data.format.nil?

      # Setup cookie headers for the request
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

        @curl.on_debug { |type, data| p data } if @debug
        
        @gzip = false
        @curl.on_header do |data|
          header, text = data.split(":").map(&:strip)
          if header == "Set-Cookie"
            # If Set-Cookie headers are given in the response, set the cookies
            parts = text.split(";")
            cookie_name, cookie_value = parts[0].split("=")
            @cookies[cookie_name] = cookie_value
          elsif header == "Content-Encoding"
            # If the respons is gzip encoded we'll have to decode it before use
            @gzip = true if text == "gzip"
          end
          data.length
        end

        params = ["http_#{method}".to_sym]
        params.push(*data) unless data.nil? or (data.is_a? Array and data.empty?)
        @curl.send(*params)
        @api_hits += 1

        raise CurbError.new(@curl) unless @curl.response_code == 200
        
        body = @gzip ? Zlib::GzipReader.new(StringIO.new(@curl.body_str)).read : @curl.body_str 

        xml = XmlSimple.xml_in(body, {'ForceArray' => false})
        raise APIError.new(xml['error']['code'], xml['error']['info']) if xml['error']

        response_xml.deep_merge! xml
        break unless xml['query-continue']
        raw_data.merge! xml['query-continue'][xml['query-continue'].keys.first]
      end

      response_xml.to_openhash
    end
    
    def logged_in?
      @config.logged_in 
    end

    def login
      return if logged_in?

      data = {
        :action     => :login, 
        :lgname     => @config.username,
        :lgpassword => @config.password
      }

      response = query_api(:post, data).login

      if response.result == "NeedToken"
        data = {
          :action     => :login, 
          :lgname     => @config.username,
          :lgpassword => @config.password,
          :lgtoken    => response.token
        }

        response = query_api(:post, data).login
      end

      raise LoginError, response.result unless response.result == "Success"

      @config.cookieprefix = response.cookieprefix 
      @config.logged_in = true
    end

    def logout
      return unless logged_in?

      query_api(:post, { :action => :logout })
      @config.logged_in = false
      @config.edit_token = nil
    end

    def edit_token(page = "Main Page")
      return nil unless logged_in?
      @config.edit_token ||= begin
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
