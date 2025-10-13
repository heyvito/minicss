# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/extensiontask"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :bench do
  desc "Run stylesheet benchmarks"
  task :stylesheet do
    ruby "benchmarks/stylesheet.rb"
  end

  desc "Run selector benchmarks"
  task :selectors do
    ruby "benchmarks/selectors.rb"
  end
end

desc "Run all benchmarks"
task bench: %w[bench:stylesheet bench:selectors]

Rake::ExtensionTask.new("minicss_scanner") do |ext|
  ext.lib_dir = "lib"
end

Rake::ExtensionTask.new("minicss_token_stream") do |ext|
  ext.lib_dir = "lib"
end
