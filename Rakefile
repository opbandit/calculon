require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rdoc/task'

Rake::TestTask.new("test") { |t|
  t.libs += ["lib", "."]
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
}

task :default => [:test]

RDoc::Task.new("doc") { |rdoc|
  rdoc.title = "Calculon - aggregate methods for models for Rails"
  rdoc.rdoc_dir = 'docs'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
}