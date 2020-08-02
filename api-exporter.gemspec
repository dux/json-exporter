version  = File.read File.expand_path '.version', File.dirname(__FILE__)
gem_name = 'api-exporter'

Gem::Specification.new gem_name, version do |s|
  s.summary     = 'Fast and intuitive api exporter'
  s.description = 'API exporter that is easy to understand, extend and use.'
  s.authors     = ["Dino Reic"]
  s.email       = 'reic.dino@gmail.com'
  s.files       = Dir['./lib/**/*.rb']+['./.version']
  s.homepage    = 'https://github.com/dux/%s' % gem_name
  s.license     = 'MIT'

  s.add_runtime_dependency 'hash_wia'
  # s.add_runtime_dependency 'fast_blank'
end