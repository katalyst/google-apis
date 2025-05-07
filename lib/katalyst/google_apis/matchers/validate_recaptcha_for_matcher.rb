# frozen_string_literal: true

module Katalyst
  module GoogleApis
    module Matchers
      def validate_recaptcha_for(attribute, expected: :recaptcha_suspicious)
        matcher = ValidateRecaptchaForMatcher.new(attribute, expected:)

        if (response = matcher.example_response(subject))
          service = instance_double(Recaptcha::AssessmentService)
          allow(service).to receive_messages(**response)
          allow(Recaptcha::AssessmentService).to receive(:call).and_return(service)
        end

        matcher
      end

      class ValidateRecaptchaForMatcher < Shoulda::Matchers::ActiveModel::ValidationMatcher
        def initialize(attribute, expected:)
          super(attribute)

          @expected_message = expected
        end

        def matches?(subject)
          Katalyst::GoogleApis.config.recaptcha.test_mode = false

          super

          disallows_value_of(example_value, @expected_message)
        ensure
          Katalyst::GoogleApis.config.recaptcha.test_mode = true
        end

        def simple_description
          "validate that :#{@attribute} includes reCAPTCHA validation"
        end

        def example_value
          {
            recaptcha_invalid:         "<invalid-token>",
            recaptcha_action_mismatch: "<action-mismatch-token>",
            recaptcha_suspicious:      "<suspicious-token>",
          }[@expected_message]
        end

        def example_response(subject)
          case @expected_message
          when :recaptcha_invalid
            { valid?: false }
          when :recaptcha_action_mismatch
            { valid?: true, action: "mismatch" }
          when :recaptcha_suspicious
            { valid?: true, action: subject.class.model_name.param_key, score: 0.1 }
          else
            { valid?: true, action: subject.class.model_name.param_key, score: 0.9 }
          end
        end
      end
    end
  end
end
