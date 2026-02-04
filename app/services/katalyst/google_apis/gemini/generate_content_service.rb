# frozen_string_literal: true

module Katalyst
  module GoogleApis
    module Gemini
      # Use Gemini GPT to generate a response to a prompt.
      class GenerateContentService
        attr_reader :response, :result, :error, :content_text

        def self.call(parent:, model:, payload:, credentials: Katalyst::GoogleApis.credentials,
                      retries: 5,
                      jitter: 1_000)
          new(parent:, model:, credentials:, attempt: 0, retries:, jitter:).call(payload:)
        end

        def initialize(credentials:, model:, parent:, attempt:, retries:, jitter:)
          @credentials = credentials
          @model = model
          @parent = parent
          @attempt = attempt
          @retries = retries
          @jitter = jitter
        end

        def call(payload:)
          @response = Curl.post(url, payload.to_json) do |http|
            http.headers["Content-Type"] = "application/json; UTF-8"
            @credentials.apply!(http.headers)
          end

          if %r{^application/json}.match?(@response.content_type)
            @result = JSON.parse(response.body, symbolize_names: true)
          else
            raise GoogleApis::Error.new(
              code:    response.response_code,
              status:  Rack::Utils::HTTP_STATUS_CODES[response.response_code],
              message: "Unexpected HTTP response received (#{response.response_code}, #{@response.content_type})",
            )
          end

          if result[:error].present?
            raise GoogleApis::Error.new(**result[:error])
          else
            @content_text = result.dig(:candidates, 0, :content, :parts, 0, :text)
          end

          self
        rescue GoogleApis::Error => e
          @error = e
          if e.code == 429 && @attempt < @retries
            Kernel.sleep(backoff)

            @response = nil
            @result = nil
            @error = nil
            @attempt += 1
            retry
          else
            raise e
          end
        rescue StandardError => e
          @error = e
          raise e
        ensure
          report_error
        end

        def success?
          result.present? && content_text.present?
        end

        def content_json
          return @content_json if instance_variable_defined?(:@content_json)

          @content_json = JSON.parse(content_text, symbolize_names: true)
        end

        def inspect
          "#<#{self.class.name} result: #{@result.inspect} error: #{@error.inspect}>"
        end

        private

        def url
          "https://aiplatform.googleapis.com/v1#{@parent}#{@model}:generateContent"
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
            category: "gemini",
            data:     {
              url:,
              method:      "POST",
              status_code: error.code,
              reason:      error.message,
            },
          )
        end

        def backoff
          [@jitter, response_headers.fetch(:retry_after, 0).to_i * 1000].max + (@jitter * rand)
        end

        def response_headers
          headers = {}
          @response.header_str.each_line do |line|
            key, value = line.split(":", 2)
            next unless value

            headers[key.underscore.to_sym] = value.strip
          end
          headers
        end
      end
    end
  end
end
