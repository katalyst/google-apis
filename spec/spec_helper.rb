# frozen_string_literal: true

require "bundler/setup"
require "logger"
require "pathname"
require "rspec"
require "webmock/rspec"

require "active_model"
require "action_view"
require "rails"
require "rails/application"

module DummyApp
  class Application < Rails::Application
    config.root = Pathname.new(__dir__).join("..")
    config.eager_load = false
    config.secret_key_base = "test"
    config.logger = Logger.new(nil)
    config.hosts = []
  end
end

require "katalyst/google_apis"

DummyApp::Application.initialize!

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
end

WebMock.disable_net_connect!(allow_localhost: true)
