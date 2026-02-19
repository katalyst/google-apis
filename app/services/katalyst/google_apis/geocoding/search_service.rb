# frozen_string_literal: true

require "curb"

module Katalyst
  module GoogleApis
    module Geocoding
      # Use Google Maps Geocoding API to find a location from an address.
      class SearchService
        attr_reader :response, :result, :error

        def self.scope
          "https://www.googleapis.com/auth/maps-platform.geocode.address"
        end

        def self.call(address:, bounds:, credentials: Katalyst::GoogleApis.credentials(scope:))
          new(credentials:).call(address:, bounds:)
        end

        def initialize(credentials:)
          @credentials = credentials
        end

        def call(address:, bounds:)
          @address = address
          @bounds = bounds

          @response = Curl.get(url, **params) do |http|
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
            api_error = result.fetch(:error)

            raise GoogleApis::Error.new(
              code:    api_error.fetch(:code, response.response_code),
              status:  api_error.fetch(:status, Rack::Utils::HTTP_STATUS_CODES[response.response_code]),
              message: api_error.fetch(:message, "Unexpected API error"),
              details: api_error.fetch(:details, nil),
            )
          end

          self
        rescue StandardError => e
          @error = e
          raise
        ensure
          report_error
        end

        def locations
          @result&.fetch(:results, nil)
        end

        def first_location
          locations&.first
        end

        def formatted_address
          first_location&.dig(:formattedAddress)
        end

        def latlng
          location = first_location&.dig(:location)
          return if location.blank?

          latitude = location[:latitude]
          longitude = location[:longitude]
          return if latitude.nil? || longitude.nil?

          [latitude, longitude].join(",")
        end

        def inspect
          "#<#{self.class.name} result: #{@result.inspect} error: #{@error.inspect}>"
        end

        private

        def url
          "https://geocode.googleapis.com/v4beta/geocode/address/#{URI.encode_uri_component(@address)}"
        end

        def params
          low, high = @bounds.split("|")

          low_lat, low_lng = low.split(",")
          high_lat, high_lng = high.split(",")

          {
            "locationBias.rectangle.low.latitude"   => low_lat,
            "locationBias.rectangle.low.longitude"  => low_lng,
            "locationBias.rectangle.high.latitude"  => high_lat,
            "locationBias.rectangle.high.longitude" => high_lng,
          }
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
            category: "geocode",
            data:     {
              url:,
              method:      "GET",
              status_code: error.try(:code),
              reason:      error.message,
            },
          )
        end
      end
    end
  end
end
