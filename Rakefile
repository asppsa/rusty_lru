require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
Dir['tasks/*.rake'].each(&method(:load))

RSpec::Core::RakeTask.new(spec: 'cargo:build')

desc 'Run Ruby and Rust tests'
task test: [:spec, 'cargo:test']
task default: :test
