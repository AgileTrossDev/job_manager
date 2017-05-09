
require "bundler/gem_tasks"
require "rake/testtask"

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))

Rake::TestTask.new do |t|
  $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), 'test'))
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

namespace :test do
  Rake::TestTask.new(:interface) do |t|
    t.libs << "test"    
    t.pattern = 'test/test_*interface*.rb'
    t.verbose = true
  end
   Rake::Task['test:interface'].comment = "Runs all interface related unit tests."
end




desc "Run tests"

task default: :test