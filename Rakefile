require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('wikibot', '0.2.2') do |p|
  p.description    = "Mediawiki Bot framework"
  p.url            = "http://github.com/dvandersluis/wiki_bot"
  p.author         = "Daniel Vandersluis"
  p.email          = "daniel@codexed.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.development_dependencies = []
  p.runtime_dependencies = ['curb >=0.5.4.0', 'xml-simple >=1.0.12', 'deep_merge >=0.1.0', 'andand >=1.3.1']
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
