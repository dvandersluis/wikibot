require 'wikibot/ext/class'
require 'wikibot/ext/hash'
require 'wikibot/vendor/openhash'
require 'wikibot/core/bot'
require 'wikibot/core/page'
require 'wikibot/core/category'
require 'wikibot/version'

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
end
