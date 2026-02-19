# frozen_string_literal: true

require "spec_helper"

RSpec.describe Katalyst::GoogleApis::Geocoding::SearchService do
  subject(:action) { described_class.call(address:, bounds:, credentials:) }

  let(:address) { "64 North Terrace" }
  let(:bounds) { "-38.06,141.00|-25.99,129.00" }
  let(:credentials) { instance_double(Katalyst::GoogleApis::Credentials) }
  let(:response) do
    { results: [
      {
        place:             "//places.googleapis.com/places/ChIJyyl6cUjJsGoRkgLldUypuxI",
        placeId:           "ChIJyyl6cUjJsGoRkgLldUypuxI",
        location:          { latitude: -34.9172454, longitude: 138.62046709999998 },
        granularity:       "ROOFTOP",
        viewport:          {
          low:  {
            latitude:  -34.9185992302915,
            longitude: 138.6190633197085,
          },
          high: {
            latitude:  -34.915901269708506,
            longitude: 138.62176128029145,
          },
        },
        bounds:            {
          low:  {
            latitude:  -34.9174444,
            longitude: 138.6202432,
          },
          high: {
            latitude:  -34.917056099999996,
            longitude: 138.62067589999998,
          },
        },
        formattedAddress:  "64 North Terrace, Kent Town SA 5067, Australia",
        postalAddress:     {
          regionCode:         "AU",
          languageCode:       "en",
          postalCode:         "5067",
          administrativeArea: "SA",
          locality:           "Kent Town",
          addressLines:       ["64 North Terrace"],
        },
        addressComponents: [
          { longText: "64", shortText: "64", types: ["street_number"] },
          { longText: "North Terrace", shortText: "North Terrace", types: ["route"], languageCode: "en" },
          { longText: "Kent Town", shortText: "Kent Town", types: ["locality", "political"], languageCode: "en" },
          { longText: "The City of Norwood Payneham and St Peters", shortText: "Norwood Payneham and St Peters",
types: ["administrative_area_level_2", "political"], languageCode: "en" },
          { longText: "South Australia", shortText: "SA", types: ["administrative_area_level_1", "political"],
languageCode: "en" },
          { longText: "Australia", shortText: "AU", types: ["country", "political"], languageCode: "en" },
          { longText: "5067", shortText: "5067", types: ["postal_code"] },
        ],
        types:             ["premise", "street_address"],
      },
    ] }
  end

  before do
    allow(credentials).to receive(:apply!)
  end

  def stub_api_request(status: 200, content_type: "application/json", response: self.response)
    stub_request(:get, /geocode.googleapis.com/).to_return(
      status:,
      headers: { "Content-Type" => content_type },
      body:    response.is_a?(String) ? response : response.to_json,
    )
  end

  it "sends request to geocoding with encoded address and bounds" do
    stub_api_request

    action

    expect(a_request(
      :get,
      "https://geocode.googleapis.com/v4beta/geocode/address/64%20North%20Terrace",
    ).with(query: {
             "locationBias.rectangle.low.latitude"   => "-38.06",
             "locationBias.rectangle.low.longitude"  => "141.00",
             "locationBias.rectangle.high.latitude"  => "-25.99",
             "locationBias.rectangle.high.longitude" => "129.00",
           })).to have_been_made.once
  end

  it "extracts and exposes location details", :aggregate_failures do
    stub_api_request

    expect(action).to have_attributes(
      formatted_address: "64 North Terrace, Kent Town SA 5067, Australia",
      latlng:            "-34.9172454,138.62046709999998",
    )
    expect(action.locations).to be_an(Array)
    expect(action.first_location).to include(formattedAddress: "64 North Terrace, Kent Town SA 5067, Australia")
  end

  it "raises service errors returned by the API" do
    stub_api_request(status: 400, response: {
                       error: {
                         code:    400,
                         message: "Invalid value at 'location_bias.rectangle.high.longitude' (TYPE_DOUBLE), \"\"",
                         status:  "INVALID_ARGUMENT",
                       },
                     })

    expect { action }.to raise_error(having_attributes(code: 400, status: "INVALID_ARGUMENT", message: /Invalid value/))
  end

  it "returns nil location details when no geocoding results are returned" do
    stub_api_request(response: { results: [] })

    expect(action).to have_attributes(locations: [], first_location: nil, formatted_address: nil, latlng: nil)
  end

  it "raises on non-json responses" do
    stub_api_request(status: 500, content_type: "text/plain", response: "")

    expect { action }.to raise_error(having_attributes(code: 500, message: /Unexpected HTTP response/))
  end

  it "raises on invalid JSON response bodies" do
    stub_api_request(response: "{ invalid")

    expect { action }.to raise_error(JSON::ParserError)
  end

  it "raises network errors" do
    stub_request(:get, /geocode.googleapis.com/).to_raise(Curl::Err::TimeoutError.new)

    expect { action }.to raise_error(Curl::Err::TimeoutError)
  end
end
