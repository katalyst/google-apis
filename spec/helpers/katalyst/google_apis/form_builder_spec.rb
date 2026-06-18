# frozen_string_literal: true

require "spec_helper"

RSpec.describe Katalyst::GoogleApis::FormBuilder do
  subject(:field) { builder.recaptcha_field(:recaptcha_token) }

  let(:builder) { ActionView::Helpers::FormBuilder.new(:quotation, model, template, {}) }
  let(:model) { form_model.new }
  let(:template) { ActionView::Base.with_view_paths([]) }

  let(:form_model) do
    Class.new do
      include ActiveModel::Model

      attr_accessor :recaptcha_token
    end
  end

  before do
    Katalyst::GoogleApis.config.recaptcha.site_key = "test-site-key"
  end

  it "renders with the default Rails form builder" do
    fragment  = Nokogiri::HTML5.fragment(field)
    recaptcha = fragment.at_css('[data-controller="recaptcha"]')
    token     = fragment.at_css('input[name="quotation[recaptcha_token]"]')

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
  end
end
