# frozen_string_literal: true

module Katalyst
  module GoogleApis
    module GOVUKFormBuilder
      def govuk_recaptcha_field(attribute = :recaptcha_token, **)
        GOVUKDesignSystemFormBuilder::Containers::FormGroup.new(self, object_name, attribute).html do
          safe_join([
                      GOVUKDesignSystemFormBuilder::Elements::ErrorMessage.new(self, object_name, attribute),
                      recaptcha_field(attribute, **),
                    ])
        end
      end
    end
  end
end
