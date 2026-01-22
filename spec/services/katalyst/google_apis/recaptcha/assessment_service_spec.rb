# frozen_string_literal: true

require "spec_helper"

RSpec.describe Katalyst::GoogleApis::Recaptcha::AssessmentService do
  subject(:action) do
    described_class.call(
      credentials:,
      parent:      "projects/identifier",
      assessment:,
    )
  end

  let(:credentials) { instance_double(Katalyst::GoogleApis::Credentials) }
  let(:assessment) { { event: { site_key: "site-key", token: "token" } } }
  let(:response) do
    {
      tokenProperties: { valid: true, action: "signup" },
      riskAnalysis:    { score: 0.9 },
    }
  end

  before do
    allow(credentials).to receive(:apply!)
  end

  def stub_api_request(status: 200, content_type: "application/json", response: self.response)
    stub_request(:post, /recaptchaenterprise.googleapis.com/).to_return(
      status:,
      headers: { "Content-Type" => content_type },
      body:    response.is_a?(String) ? response : response.to_json,
    )
  end

  def stub_api_error(exception:)
    stub_request(:post, /recaptchaenterprise.googleapis.com/).to_return(exception:)
  end

  it "sends assessment payload to recaptcha intact" do
    stub_api_request

    action
    expect(a_request(:post,
                     "https://recaptchaenterprise.googleapis.com/v1/projects/identifier/assessments")
      .with(body: assessment.to_json))
      .to have_been_made.once
  end

  it "extracts and exposes the assessment result" do
    stub_api_request

    expect(action).to have_attributes(valid?: true, action: "signup", score: 0.9)
  end

  it "returns nil action and score when invalid" do
    response = { tokenProperties: { valid: false, action: "signup" } }

    stub_api_request(response:)

    expect(action).to have_attributes(valid?: false, action: nil, score: nil)
  end

  it "raises unexpected protocol errors" do
    stub_api_error(exception: Curl::Err::TimeoutError.new)

    expect { action }.to raise_error(Curl::Err::TimeoutError)
  end

  it "raises unexpected network errors" do
    stub_api_request(status: 500, content_type: "text/plain", response: "")

    expect { action }.to raise_error(having_attributes(code: 500, message: /Unexpected/))
  end

  it "raises on expected content type responses" do
    stub_api_request(status: 200, content_type: "text/html", response: "<html>")

    expect { action }.to raise_error(having_attributes(code: 200, message: /Unexpected/))
  end

  it "throws invalid response formatting errors" do
    stub_api_request(response: "{ invalid")

    expect { action }.to raise_error(JSON::ParserError)
  end
end
