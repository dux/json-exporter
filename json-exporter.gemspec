version  = File.read File.expand_path '.version', File.dirname(__FILE__)
gem_name = 'json-exporter'

Gem::Specification.new gem_name, version do |s|
  s.summary     = 'Fast, simple & powerful object exporter'
  s.description = 'Fast ruby object JSON exporter, easy to use and extend'
  s.authors     = ["Dino Reic"]
  s.email       = 'reic.dino@gmail.com'
  s.files       = Dir['./lib/**/*.rb']+['./.version']
  s.homepage    = 'https://github.com/dux/%s' % gem_name
  s.license     = 'MIT'

  s.add_runtime_dependency 'hash_wia'
end