# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wikibot}
  s.version = "0.2.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Vandersluis"]
  s.date = %q{2012-02-07}
  s.description = %q{Mediawiki Bot framework}
  s.email = %q{daniel@codexed.com}
  s.extra_rdoc_files = ["README.textile", "lib/wikibot.rb", "lib/wikibot/core/bot.rb", "lib/wikibot/core/category.rb", "lib/wikibot/core/page.rb", "lib/wikibot/ext/hash.rb", "lib/wikibot/vendor/openhash.rb", "lib/wikibot/version.rb"]
  s.files = ["README.textile", "Rakefile", "lib/wikibot.rb", "lib/wikibot/core/bot.rb", "lib/wikibot/core/category.rb", "lib/wikibot/core/page.rb", "lib/wikibot/ext/hash.rb", "lib/wikibot/vendor/openhash.rb", "lib/wikibot/version.rb", "wikibot.gemspec", "Manifest"]
  s.homepage = %q{http://github.com/dvandersluis/wiki_bot}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Wikibot", "--main", "README.textile"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{wikibot}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Mediawiki Bot framework}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<curb>, [">= 0.5.4.0"])
      s.add_runtime_dependency(%q<xml-simple>, [">= 1.0.12"])
      s.add_runtime_dependency(%q<deep_merge>, [">= 0.1.0"])
      s.add_runtime_dependency(%q<andand>, [">= 1.3.1"])
    else
      s.add_dependency(%q<curb>, [">= 0.5.4.0"])
      s.add_dependency(%q<xml-simple>, [">= 1.0.12"])
      s.add_dependency(%q<deep_merge>, [">= 0.1.0"])
      s.add_dependency(%q<andand>, [">= 1.3.1"])
    end
  else
    s.add_dependency(%q<curb>, [">= 0.5.4.0"])
    s.add_dependency(%q<xml-simple>, [">= 1.0.12"])
    s.add_dependency(%q<deep_merge>, [">= 0.1.0"])
    s.add_dependency(%q<andand>, [">= 1.3.1"])
  end
end
