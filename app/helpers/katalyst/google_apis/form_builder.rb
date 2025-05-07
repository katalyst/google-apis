# frozen_string_literal: true

module Katalyst
  module GoogleApis
    module FormBuilder
      def recaptcha_field(attribute = :recaptcha_token, action: object_name,
sitekey: GoogleApis.config.recaptcha.site_key)
        safe_join([
                    content_tag(:div, "", data: { action:, controller: "recaptcha", sitekey: }),
                    hidden_field(attribute),
                  ])
      end
    end
  end
end
