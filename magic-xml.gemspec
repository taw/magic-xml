Gem::Specification.new do |gem|
  gem.authors       = ["Tomasz Wegrzanowski"]
  gem.email         = ["Tomasz.Wegrzanowski@gmail.com"]
  gem.description   = "The best Ruby library for handling XML"
  gem.summary       = "The best Ruby library for handling XML"
  gem.homepage      = "https://github.com/taw/magic-xml"
  gem.files         = Dir["lib/*"]
  gem.test_files    = Dir["tests/**"]
  gem.name          = "magic-xml"
  gem.require_paths = ["lib"]
  gem.version       = "0.2013.04.14"
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end
