# frozen_string_literal: true

require "spec_helper"
require "govuk_design_system_formbuilder"

RSpec.describe Katalyst::GoogleApis::GOVUKFormBuilder do
  subject(:field) { builder.govuk_recaptcha_field(:recaptcha_token) }

  let(:builder) do
    Class.new(GOVUKDesignSystemFormBuilder::FormBuilder) do
      include Katalyst::GoogleApis::GOVUKFormBuilder
    end.new(:quotation, model, template, {})
  end
  let(:model) { form_model.new }
  let(:template) { ActionView::Base.with_view_paths([]) }

  let(:form_model) do
    Class.new do
      include ActiveModel::Model

      def self.model_name
        ActiveModel::Name.new(self, nil, "Quotation")
      end

      attr_accessor :recaptcha_token
    end
  end

  before do
    Katalyst::GoogleApis.config.recaptcha.site_key = "test-site-key"
  end

  it "renders within a govuk form group", :aggregate_failures do
    fragment   = Nokogiri::HTML5.fragment(field)
    form_group = fragment.at_css(".govuk-form-group")
    recaptcha  = fragment.at_css('[data-controller="recaptcha"]')
    token      = fragment.at_css('input[name="quotation[recaptcha_token]"]')

    expect(form_group).to be_present
    expect(
      recaptcha.attributes.slice(
        "data-recaptcha-action-value",
        "data-recaptcha-site-key-value",
      ).transform_values(&:value).merge("token_name" => token["name"]),
    ).to eq(
      "data-recaptcha-action-value"   => "quotation",
      "data-recaptcha-site-key-value" => "test-site-key",
      "token_name"                    => "quotation[recaptcha_token]",
    )
    expect(recaptcha["id"]).to eq("quotation-recaptcha-token-field")
    expect(recaptcha["class"]).to eq("govuk-recaptcha")
  end

  context "with errors" do
    before { model.errors.add(:recaptcha_token, :invalid) }

    it "renders error classes and message", :aggregate_failures do
      fragment      = Nokogiri::HTML5.fragment(field)
      form_group    = fragment.at_css(".govuk-form-group")
      error_message = fragment.at_css(".govuk-error-message")
      recaptcha     = fragment.at_css('[data-controller="recaptcha"]')

      expect(form_group["class"]).to include("govuk-form-group--error")
      expect(error_message).to be_present
      expect(recaptcha["id"]).to eq("quotation-recaptcha-token-field")
      expect(recaptcha["class"]).to include("govuk-recaptcha--error")
      expect(recaptcha["aria-describedby"]).to eq("quotation-recaptcha-token-error")
    end
  end
end
