# frozen_string_literal: true

require "spec_helper"

RSpec.describe Katalyst::GoogleApis::Gemini::GenerateContentService do
  subject(:action) do
    described_class.call(
      credentials:,
      parent:      "/projects/identifier/locations/australia-southeast1",
      model:       "/publishers/google/models/gemini-3-flash-preview",
      payload:,
    )
  end

  let(:credentials) { instance_double(Katalyst::GoogleApis::Credentials) }
  let(:payload) { { contents: [{ role: "user", parts: [{ text: "What is AI?" }] }] } }
  let(:response) { { candidates: [{ content: { parts: [{ text: content_json.to_json }] } }] } }
  let(:content_json) { { key: "value" } }

  before do
    allow(credentials).to receive(:apply!)
  end

  def stub_api_request(status: 200, content_type: "application/json", response: self.response)
    stub_request(:post, /aiplatform.googleapis.com/).to_return(
      status:,
      headers: { "Content-Type" => content_type },
      body:    response.is_a?(String) ? response : response.to_json,
    )
  end

  it "sends payload to gemini intact" do
    stub_api_request

    action
    expect(a_request(:post,
                     %w[https://aiplatform.googleapis.com/v1
                        /projects/identifier/locations/australia-southeast1
                        /publishers/google/models/gemini-3-flash-preview
                        :generateContent].join).with(body: payload.to_json))
      .to have_been_made.once
  end

  it "extracts and parses the result" do
    stub_api_request

    expect(action).to have_attributes(success?: true, content_json:)
  end

  it "extracts and returns service errors" do
    response = { error: {
      code:    400,
      message: "Invalid JSON payload received. Unknown name \"invalid\": Cannot find field.",
      status:  "INVALID_ARGUMENT",
    } }

    stub_api_request(status: 400, response:)

    expect(action).to have_attributes(success?: false, error: have_attributes(**response[:error]))
  end

  it "throws authentication errors" do
    error = Aws::Errors::InvalidSSOToken.new("The SSO session associated with this profile has expired")

    allow(credentials).to receive(:apply!).and_raise(error)

    expect { action }.to raise_error(error)
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

  it "throws invalid content parser errors" do
    response = { candidates: [{ content: { parts: [{ text: "not a json string" }] } }] }

    stub_api_request(response:)

    expect { action.content_json }.to raise_error(JSON::ParserError)
  end
end
