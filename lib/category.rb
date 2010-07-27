module WikiBot
  class Category < Page
    def category_info
      @category_info ||= begin
        data = {
          :action => :query,
          :titles => @name,
          :prop => :categoryinfo
        }

        # The query API returns nothing for an empty cat, so we'll return a hash with all the normal
        # properties set to 0 instead
        empty_cat = { :pages => 0, :size => 0, :files => 0, :subcats => 0, :hidden => "" }.to_openhash
        @wiki_bot.query_api(:get, data).query.pages.page.categoryinfo || empty_cat
      end
    end

    def members(sort = :sortkey, dir = :desc, namespace = nil)
      @members ||= begin
        data = {
          :action => :query,
          :list => :categorymembers,
          :cmtitle => @name,
          :cmsort => sort,
          :cmdir => dir,
          :cmnamespace => namespace
        }

        @wiki_bot.query_api(:get, data).query.categorymembers.cm.map { |m| Page.new(@wiki_bot, m["title"]) }
      end
    end

    # Returns a hash of how many pages live in a category
    def count(include_subcats = false)
      @count ||= begin
        out = {}
        ci = category_info

        out[@name] = {
          :pages => ci.pages.to_i
        }

        if include_subcats and ci.subcats.to_i > 0
          out[@name][:subcats] = {}
          members.each do |m|
            out[@name][:subcats].merge! self.class.new(@wiki_bot, m["title"]).count(include_subcats)
          end
        end

        out
      end
    end
  end
end
