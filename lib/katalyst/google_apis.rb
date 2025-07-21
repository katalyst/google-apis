# frozen_string_literal: true

require "active_support"
require "katalyst/google_apis/engine"

module Katalyst
  module GoogleApis
    extend self
    extend ActiveSupport::Autoload

    autoload :Config

    def config
      @config ||= Config.new
    end

    def configure
      yield(config)
    end

    def credentials(scope: "https://www.googleapis.com/auth/cloud-platform")
      @credentials        ||= {}
      @credentials[scope] ||= Credentials.new(
        project_number:        config.project_number,
        service_account_email: config.service_account_email,
        identity_pool:         config.identity_pool,
        identity_provider:     config.identity_provider,
        scope:,
      )
    end
  end
end
