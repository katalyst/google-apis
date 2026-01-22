# frozen_string_literal: true

require "curb"

module Katalyst
  module GoogleApis
    module Recaptcha
      class AssessmentService
        attr_accessor :response, :result, :error

        def self.call(assessment:, parent:, credentials: GoogleApis.credentials)
          new(credentials:, parent:).call(assessment:)
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

          if %r{^application\/json}.match?(@response.content_type)
            @result = JSON.parse(response.body, symbolize_names: true)
          else
            raise GoogleApis::Error.new(
              code:    response.response_code,
              status:  Rack::Utils::HTTP_STATUS_CODES[response.response_code],
              message: "Unexpected HTTP response received (#{response.response_code}, #{@response.content_type})",
            )
          end

          self
        rescue StandardError => e
          @error = e
          raise e
        ensure
          report_error
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

        def report_error
          return if error.nil?

          if defined?(Sentry)
            Sentry.add_breadcrumb(sentry_breadcrumb(error))
          else
            Rails.logger.error(error)
          end
        end

        def sentry_breadcrumb(error)
          Sentry::Breadcrumb.new(
            type:     "http",
            category: "recaptcha",
            data:     {
              url:,
              method:      "POST",
              status_code: error.code,
              reason:      error.message,
            },
          )
        end
      end
    end
  end
end
