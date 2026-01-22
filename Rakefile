# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require "rubocop/katalyst/rake_task"
RuboCop::Katalyst::RakeTask.new

require "rubocop/katalyst/prettier_task"
RuboCop::Katalyst::PrettierTask.new

desc "Run security checks"
task security: :environment do
  sh "bundle exec brakeman -q -w2"
end

desc "Dummy rails environment for katalyst-rubocop"
task :environment

task default: %i[lint spec security] do
  puts "🎉 build complete! 🎉"
end
