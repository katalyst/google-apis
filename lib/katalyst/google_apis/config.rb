# frozen_string_literal: true

module Katalyst
  module GoogleApis
    class Config
      attr_accessor :project_id, :project_number, :service_account_email, :identity_pool, :identity_provider, :recaptcha

      def initialize
        @project_id            = ENV.fetch("GOOGLE_PROJECT_ID", nil)
        @project_number        = ENV.fetch("GOOGLE_PROJECT_NUMBER", nil)
        @service_account_email = ENV.fetch("GOOGLE_SERVICE_ACCOUNT_EMAIL", nil)
        @identity_pool         = ENV.fetch("GOOGLE_OIDC_IDENTITY_POOL", nil)
        @identity_provider     = ENV.fetch("GOOGLE_OIDC_IDENTITY_PROVIDER", nil)
        @recaptcha             = ActiveSupport::OrderedOptions.new.tap do |defaults|
          defaults.site_key  = ENV.fetch("GOOGLE_RECAPTCHA_SITE_KEY", nil)
          defaults.score     = ENV.fetch("GOOGLE_RECAPTCHA_SCORE", 0.5).to_f
          defaults.test_mode = !ENV.fetch("VERIFY_RECAPTCHA", !Rails.env.local?)
        end
      end
    end
  end
end
