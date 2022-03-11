# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

Rake::TestTask.new(:benchmark) do |t|
  t.libs << 'benchmark'
  t.libs << 'lib'
  t.test_files = FileList['benchmark/**/*_benchmark.rb']
end
require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[test rubocop]
