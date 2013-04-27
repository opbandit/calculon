lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'
require 'calculon/version'

Rake::TestTask.new("test") { |t|
  t.libs += ["lib", "."]
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
}

task :default => [:test]

YARD::Rake::YardocTask.new(:doc) do |task|
  task.files  = FileList["lib/**/*.rb"]
  task.options = "--output", "docs", "--title", "Calculon #{Calculon::VERSION}", "--main", "README.md"
end
