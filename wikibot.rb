Dir[File.dirname(__FILE__) + '/ext/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/wikibot/*.rb'].each {|file| require file }

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
