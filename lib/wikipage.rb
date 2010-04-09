class WikiPage
  class WriteError < StandardError; end

  attr_writer :wiki_bot

  def initialize(wiki_bot, name)
    @wiki_bot = wiki_bot
    @name = name
  end

  ###
  # Read from page
  def content
    @content ||= begin
      data = {
        :action => :query,
        :titles => @name,
        :prop => :revisions,
        :rvprop => :content
      }

      @wiki_bot.query_api(:get, data)['query']['pages']['page']['revisions']['rev']
    end

    @content["content"]
  end

  ###
  # Write to page
  def write(text, summary, section = nil, minor = false)
    return if @wiki_bot.debug

    data = {
      :action => :edit,
      :title => @name,

      :text => text,
      :token => @wiki_bot.edit_token,
      :summary => summary,
      :recreate => 1,
      :bot => 1
    }

    data[:section] = section if !section.nil?
    data[:minor] = 1 if minor
    data[:notminor] = 1 if !minor
  
    result = @wiki_bot.query_api(:post, data)
    status = result['edit']['result']
    @wiki_bot.page_writes += 1
    raise WriteError, status unless status == "Success"
  end

  ###
  # Get page information
  def category_info
    data = {
      :action => :query,
      :titles => @name,
      :prop => :categoryinfo
    }

    # The query API returns nothing for an empty cat, so we'll return a hash with all the normal
    # properties set to 0 instead
    empty_cat = { "pages" => 0, "size" => 0, "files" => 0, "subcats" => 0, "hidden" => "" }
    @wiki_bot.query_api(:get, data)['query']['pages']['page']['categoryinfo'] || empty_cat
  end

  def members(sort = :sortkey, dir = :desc, namespace = nil)
    data = {
      :action => :query,
      :list => :categorymembers,
      :cmtitle => @name,
      :cmsort => sort,
      :cmdir => dir,
      :cmnamespace => namespace
    }

    @wiki_bot.query_api(:get, data)['query']['categorymembers']['cm']
  end

  # Returns a hash of how many pages live in a category
  def count(include_subcats = false)
    out = {}
    ci = category_info

    out[@name] = {
      :pages => ci['pages'].to_i
    }

    if include_subcats and ci['subcats'].to_i > 0
      out[@name][:subcats] = {}
      members.each do |m|
        out[@name][:subcats].merge! WikiPage.new(@wiki_bot, m['title']).count(include_subcats)
      end
    end

    out
  end
end
