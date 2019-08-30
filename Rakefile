require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
load 'tasks/cargo.rake'

RSpec::Core::RakeTask.new(spec: 'cargo:build')

task test: [:spec, 'cargo:test']
task default: :test
