# frozen_string_literal: true

module Katalyst
  module GoogleApis
    class Config
      include ActiveSupport::Configurable

      config_accessor(:project_id) { ENV.fetch("GOOGLE_PROJECT_ID", nil) }
      config_accessor(:project_number) { ENV.fetch("GOOGLE_PROJECT_NUMBER", nil) }
      config_accessor(:service_account_email) { ENV.fetch("GOOGLE_SERVICE_ACCOUNT_EMAIL", nil) }
      config_accessor(:identity_pool) { ENV.fetch("GOOGLE_OIDC_IDENTITY_POOL", nil) }
      config_accessor(:identity_provider) { ENV.fetch("GOOGLE_OIDC_IDENTITY_PROVIDER", nil) }

      config_accessor(:recaptcha) do
        defaults           = ActiveSupport::OrderedOptions.new
        defaults.site_key  = ENV.fetch("GOOGLE_RECAPTCHA_SITE_KEY", nil)
        defaults.score     = ENV.fetch("GOOGLE_RECAPTCHA_SCORE", 0.5).to_f
        defaults.test_mode = !ENV.fetch("VERIFY_RECAPTCHA", !Rails.env.local?) # rubocop:disable Rails/UnknownEnv
        defaults
      end
    end
  end
end
