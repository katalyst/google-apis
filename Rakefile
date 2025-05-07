# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"
require "rubocop/rake_task"

require "rubocop/katalyst/rake_task"
RuboCop::Katalyst::RakeTask.new

desc "Run all linters"
task lint: %w[rubocop]

desc "Run all auto-formatters"
task format: %w[rubocop:autocorrect]

task default: %i[lint] do
  puts "🎉 build complete! 🎉"
end
