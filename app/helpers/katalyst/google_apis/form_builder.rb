# frozen_string_literal: true

module Katalyst
  module GoogleApis
    module FormBuilder
      def recaptcha_field(attribute = :recaptcha_token, action: object_name,
                          site_key: GoogleApis.config.recaptcha.site_key)
        safe_join([
                    RecaptchaField.new(action:, attribute:, site_key:).render(self),
                    hidden_field(attribute),
                  ])
      end

      class RecaptchaField
        attr_reader :action, :attribute, :site_key

        def initialize(action:, attribute:, site_key:)
          # rubocop:disable Rails/HelperInstanceVariable
          @action    = action
          @attribute = attribute
          @site_key  = site_key
          # rubocop:enable Rails/HelperInstanceVariable
        end

        def render(template)
          template.tag.div(data:)
        end

        private

        def data
          {
            controller:               "recaptcha",
            action:                   "turbo:before-morph-element->recaptcha#morph",
            recaptcha_action_value:   action,
            recaptcha_site_key_value: site_key,
          }
        end
      end
    end
  end
end
