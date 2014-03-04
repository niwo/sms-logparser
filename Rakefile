require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs << 'spec'
  test.test_files = FileList['spec/*_spec.rb']
end

desc "Run Tests"
task :default => :test
