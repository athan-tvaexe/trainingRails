# This file needs to be run with RSpec, not Minitest.
# Make sure you have added the 'rspec-rails' gem to your Gemfile.
require 'rails_helper'

RSpec.describe WeatherController, type: :request do
  # Include the WebMock::API module so its methods can be used
  include WebMock::API

  before do
    # Disable real API calls
    WebMock.disable_net_connect!

    # Set up mock responses for the OpenWeatherMap API
    @valid_response = {
      "name": "Tokyo",
      "main": { "temp": 27.38 },
      "weather": [ { "description": "light rain" } ]
    }.to_json

    @osaka_response = {
      "name": "Osaka",
      "main": { "temp": 31.45 },
      "weather": [ { "description": "broken clouds" } ]
    }.to_json

    @not_found_response = {
      "cod": "404",
      "message": "city not found"
    }.to_json

    # Configure a mock API key for the test environment
    ENV["OPENWEATHER_API_KEY"] = "12e5c3cf992f50c8f84a90ae0ba1669d"

    # Clear the cache before each test run to ensure accurate results
    Rails.cache.clear
  end

  after do
    # Restore the ability to make real API calls after the tests finish
    WebMock.allow_net_connect!
  end

  # --- Tests for the 'index' action ---

  describe 'GET /weather' do
    context 'with a valid city' do
      it 'returns weather data and a successful response' do
        stub_request(:get, /api.openweathermap.org/).to_return(body: @valid_response, status: 200)

        get weather_url, params: { city: "Tokyo" }
        expect(response).to be_successful
        expect(JSON.parse(response.body)["city"]).to eq("Tokyo")
        expect(JSON.parse(response.body)["temp_celsius"]).to be_within(0.01).of(27.38)
      end
    end

    context 'when the city parameter is missing' do
      it 'returns 400 bad request' do
        get weather_url
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("City parameter is required")
      end
    end

    context 'when there is an error from the external API' do
      it 'returns 502 service unavailable' do
        stub_request(:get, /api.openweathermap.org/).to_return(body: @not_found_response, status: 404)

        get weather_url, params: { city: "InvalidCity" }
        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)["error"]).to eq("External API error: 404")
      end
    end

    context 'when the API key is not configured' do
      it 'returns 502 service unavailable' do
        ENV["OPENWEATHER_API_KEY"] = nil
        get weather_url, params: { city: "Tokyo" }
        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)["error"]).to eq("API key is not configured")
      end
    end

    context 'with caching' do
      it 'uses the cache for subsequent requests to the same city' do
        # This is the correct syntax to verify the number of API calls
        stub_request(:get, /api.openweathermap.org/).to_return(body: @valid_response, status: 200).times(1)

        # First call, which will hit the real API
        get weather_url, params: { city: "Tokyo" }
        expect(response).to be_successful

        # Second call, which will use the cache
        get weather_url, params: { city: "Tokyo" }
        expect(response).to be_successful

        # Check the number of API calls
        expect(a_request(:get, /api.openweathermap.org/)).to have_been_made.times(1)
    
    # オプション2: 最大1回まで（at_mostの代替）
        expect(WebMock).to have_requested(:get, /api.openweathermap.org/).at_most_times(1)
      end
    end
  end

  # --- Tests for the 'bulk' action ---

  describe 'GET /weather/bulk' do
    context 'with multiple valid cities' do
      it 'returns weather data for all cities' do
        stub_request(:get, /q=Tokyo/).to_return(body: @valid_response, status: 200)
        stub_request(:get, /q=Osaka/).to_return(body: @osaka_response, status: 200)

        get weather_bulk_url, params: { cities: "Tokyo,Osaka" }
        expect(response).to be_successful
        parsed_response = JSON.parse(response.body)
        expect(parsed_response.count).to eq(2)
        expect(parsed_response.first["city"]).to eq("Tokyo")
        expect(parsed_response.last["city"]).to eq("Osaka")
      end
    end

    context 'when there are both valid and invalid cities' do
      it 'gracefully handles invalid cities and returns data for the valid ones' do
        stub_request(:get, /q=Tokyo/).to_return(body: @valid_response, status: 200)
        stub_request(:get, /q=InvalidCity/).to_return(body: @not_found_response, status: 404)

        get weather_bulk_url, params: { cities: "Tokyo,InvalidCity" }
        expect(response).to be_successful
        parsed_response = JSON.parse(response.body)
        expect(parsed_response.count).to eq(1)
        expect(parsed_response.first["city"]).to eq("Tokyo")
      end
    end

    context 'with an empty cities parameter' do
      it 'returns an empty array' do
        get weather_bulk_url, params: { cities: "" }
        expect(response).to be_successful
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end
end
