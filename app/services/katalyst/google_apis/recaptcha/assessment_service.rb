# frozen_string_literal: true

require "curb"

module Katalyst
  module GoogleApis
    module Recaptcha
      class AssessmentService
        attr_accessor :response, :result, :error

        def self.call(parent:, credentials: GoogleApis.credentials, **)
          new(credentials:, parent:).call(**)
        end

        def initialize(credentials:, parent:)
          @credentials = credentials
          @parent      = parent
        end

        def call(assessment:)
          @response = Curl.post(url, assessment.to_json) do |http|
            http.headers["Content-Type"] = "application/json; UTF-8"
            @credentials.apply!(http.headers)
          end

          @result = JSON.parse(@response.body, symbolize_names: true)

          self
        rescue Curl::Easy::Error => e
          if defined?(Sentry)
            Sentry.add_breadcrumb(sentry_breadcrumb(e))
          else
            Rails.logger.error(e)
          end

          @error = e
          self
        end

        def valid?
          @result.present? && @result.dig(:tokenProperties, :valid)
        end

        def action
          return nil unless valid?

          @result.dig(:tokenProperties, :action)
        end

        def score
          return nil unless valid?

          @result.dig(:riskAnalysis, :score)
        end

        def inspect
          "#<#{self.class.name} result: #{@result.inspect} error: #{@error.inspect}>"
        end

        private

        def url
          "https://recaptchaenterprise.googleapis.com/v1/#{@parent}/assessments"
        end

        def sentry_breadcrumb(error)
          Sentry::Breadcrumb.new(
            type:        "http",
            category:    "recaptcha",
            url:,
            method:      "POST",
            status_code: error.code,
            reason:      error.message,
          )
        end
      end
    end
  end
end
