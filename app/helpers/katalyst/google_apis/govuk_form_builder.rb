# frozen_string_literal: true

module Katalyst
  module GoogleApis
    module GOVUKFormBuilder
      # Generates a Google recaptcha input that shows errors.
      #
      # @param attribute_name [Symbol] The name of the attribute
      # @option kwargs [Hash] kwargs additional arguments are applied as attributes to the +input+ element
      # @param form_group [Hash] configures the form group
      # @option form_group kwargs [Hash] additional attributes added to the form group
      # @param before_input [String,Proc] the content injected before the input. No content will be added if left +nil+
      # @param after_input [String,Proc] the content injected after the input. No content will be added if left +nil+
      # @return [ActiveSupport::SafeBuffer] HTML output
      #
      # @example A google recaptcha input
      #   = f.govuk_recaptcha_field
      #
      def govuk_recaptcha_field(attribute_name = :recaptcha_token,
                                form_group: {}, before_input: nil, after_input: nil, **)
        Recaptcha.new(self, object_name, attribute_name, form_group:, before_input:, after_input:, **).html
      end

      class Recaptcha < GOVUKDesignSystemFormBuilder::Base
        include GOVUKDesignSystemFormBuilder::Traits::Error
        include GOVUKDesignSystemFormBuilder::Traits::HTMLAttributes
        include GOVUKDesignSystemFormBuilder::Traits::ContentBeforeAndAfter

        def initialize(builder, object_name, attribute_name, form_group:, before_input:, after_input:, **kwargs)
          super(builder, object_name, attribute_name)

          @html_attributes      = kwargs
          @form_group           = form_group
          @before_input         = before_input
          @after_input          = after_input
        end

        def html
          GOVUKDesignSystemFormBuilder::Containers::FormGroup.new(*bound, **@form_group).html do
            safe_join([error_element, content])
          end
        end

        private

        def content
          safe_join([
                      before_input_content,
                      input,
                      after_input_content,
                    ])
        end

        def input
          @builder.send(:recaptcha_field, @attribute_name, **attributes(@html_attributes))
        end

        def options
          {
            id:    field_id(link_errors: true),
            class: classes,
            aria:  { describedby: combine_references(error_id) },
          }
        end

        def classes
          [%(#{brand}-recaptcha)].push(error_classes).compact
        end

        def error_classes
          %(#{brand}-recaptcha--error) if has_errors?
        end
      end
    end
  end
end
