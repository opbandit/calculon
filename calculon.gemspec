lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'calculon/version'

Gem::Specification.new do |gem|
  gem.name          = "calculon"
  gem.version       = Calculon::VERSION
  gem.authors       = ["Brian Muller"]
  gem.email         = ["bamuller@gmail.com"]
  gem.description   = %q{Calculon provides aggregate time functions for ActiveRecord.}
  gem.summary       = %q{Calculon provides aggregate time functions for ActiveRecord.}
  gem.homepage      = "https://github.com/opbandit/calculon"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency("rails", ">= 3.2.0")
  gem.add_development_dependency('yard')
  gem.add_development_dependency('redcarpet')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('sqlite3')
  gem.add_development_dependency('mysql2')
  gem.add_development_dependency('rubocop')
end
