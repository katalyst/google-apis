# frozen_string_literal: true

module Katalyst
  module GoogleApis
    # rubocop:disable Rails/HelperInstanceVariable
    module FormBuilder
      ##
      # :method: recaptcha_field
      #
      # :call-seq: recaptcha_field(method = :recaptcha_token, options = {})
      #
      #   <%= form_with model: @contact do |f| %>
      #     <%= f.recaptcha_field %>
      #   <% end %>
      #
      # Please refer to the documentation of the base helper for details.
      def recaptcha_field(attribute = :recaptcha_token, site_key: GoogleApis.config.recaptcha.site_key, **)
        RecaptchaField.new(@object_name, attribute, site_key:, **).render(@template)
      end

      class RecaptchaField
        def initialize(object_name, attribute, site_key:, **html_attributes)
          @object_name     = object_name
          @attribute       = attribute
          @site_key        = site_key
          @html_attributes = html_attributes
        end

        def render(template)
          template.safe_join([template.tag.div(**@html_attributes, data:),
                              template.hidden_field(@object_name, @attribute)])
        end

        private

        def data
          {
            controller:               "recaptcha",
            action:                   "turbo:before-morph-element->recaptcha#morph",
            recaptcha_action_value:   @object_name,
            recaptcha_site_key_value: @site_key,
          }
        end
      end
    end
    # rubocop:enable Rails/HelperInstanceVariable
  end
end
