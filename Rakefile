require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('wikibot', '0.2.0') do |p|
  p.description    = "Mediawiki Bot framework"
  p.url            = "http://github.com/dvandersluis/wiki_bot"
  p.author         = "Daniel Vandersluis"
  p.email          = "daniel@codexed.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.development_dependencies = []
  p.runtime_dependencies = ['taf2-curb', 'xml-simple', 'deep_merge']
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
