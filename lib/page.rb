module WikiBot
  class Page
    class WriteError < StandardError; end

    attr_writer :wiki_bot
    attr_reader :name

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

        @wiki_bot.query_api(:get, data).query.pages.page.revisions.rev.content
      end
    end

    # Parse page content
    def text
      @text ||= begin
        data = {
          :action => :parse,
          :page => @name
        }

        @wiki_bot.query_api(:get, data).parse.text.content
      end
    end

    ###
    # Get page categories
    def categories(show = :all)
      # Cache hidden and non-hidden categories separately
      @categories ||= begin
        puts "Loading category data"
        data = {
          :action => :query,
          :titles => @name,
          :prop => :categories,
          :clshow => "!hidden"
        }

        categories = @wiki_bot.query_api(:get, data).query.pages.page.categories.cl
        categories = categories.inject([]) do |memo, category|
          memo.push(WikiBot::Category.new(@wiki_bot, category.title))
        end
        
        data = {
          :action => :query,
          :titles => @name,
          :prop => :categories,
          :clshow => "hidden"
        }

        hidden_categories = @wiki_bot.query_api(:get, data).query.pages.page.categories.cl
        hidden_categories = hidden_categories.inject([]) do |memo, category|
          memo.push(WikiBot::Category.new(@wiki_bot, category.title))
        end

        {:nonhidden => categories, :hidden => hidden_categories}
      end

      show = :all unless [:all, :hidden, :nonhidden].include? show
      return @categories[:nonhidden] + @categories[:hidden] if show == :all
      @categories[show]
    end

    def category_names(show = :all)
      categories(show).map{ |c| c.name }
    end

    ###
    # Write to page
    def write(text, summary, section = nil, minor = false)
      return if @wiki_bot.debug or @wiki_bot.readonly

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
      status = result.edit.result
      @wiki_bot.page_writes += 1
      raise WriteError, status unless status == "Success"
    end
  end
end
