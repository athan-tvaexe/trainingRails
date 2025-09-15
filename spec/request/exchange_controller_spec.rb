# spec/requests/exchange_controller_spec.rb
require 'rails_helper'

RSpec.describe ExchangeController, type: :request do
  include WebMock::API

  before do
    # Disable real network connections
    WebMock.disable_net_connect!

    # Mock responses from the exchange rate API
    @valid_response = {
      "result" => "success",
      "conversion_rate" => 0.85
    }.to_json

    @api_error_response = {
      "result" => "error",
      "error-type" => "unsupported-code"
    }.to_json

    # Set a mock API key for the test environment
    ENV["EXCHANGE_API_KEY"] = "fake_api_key"

    # Clear the cache before each test to ensure isolation
    Rails.cache.clear
  end

  after do
    # Re-enable network connections after tests are done
    WebMock.allow_net_connect!
  end

  describe 'GET /convert' do
    context 'with valid parameters' do
      before do
        stub_request(:get, /v6.exchangerate-api.com/)
          .to_return(body: @valid_response, status: 200, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns a successful conversion when amount is provided' do
        get convert_url, params: { from: 'USD', to: 'EUR', amount: 100 }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response['from']).to eq('USD')
        expect(json_response['to']).to eq('EUR')
        expect(json_response['original_amount']).to eq(100.0)
        expect(json_response['converted_amount']).to eq(85.00) # 100 * 0.85
        expect(json_response['rate']).to eq(0.85)
      end

      it 'defaults amount to 1.0 when not provided' do
        get convert_url, params: { from: 'USD', to: 'EUR' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response['original_amount']).to eq(1.0)
        expect(json_response['converted_amount']).to eq(0.85) # 1 * 0.85
      end
    end

    context 'with invalid or missing parameters' do
      it 'returns a bad request if "from" is missing' do
        get convert_url, params: { to: 'EUR', amount: 100 }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq("'from' and 'to' are required parameters")
      end

      it 'returns a bad request if "to" is missing' do
        get convert_url, params: { from: 'USD', amount: 100 }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq("'from' and 'to' are required parameters")
      end

      it 'returns a bad request if amount is zero' do
        get convert_url, params: { from: 'USD', to: 'EUR', amount: 0 }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq("amount must be a positive number")
      end

      it 'returns a bad request if amount is negative' do
        get convert_url, params: { from: 'USD', to: 'EUR', amount: -50 }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq("amount must be a positive number")
      end
    end

    context 'when handling external API issues' do
      it 'returns an internal server error if API key is missing' do
        ENV["EXCHANGE_API_KEY"] = nil
        get convert_url, params: { from: 'USD', to: 'EUR', amount: 100 }

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq("API key is not configured")
      end

      it 'returns a service unavailable error on connection failure' do
        stub_request(:get, /v6.exchangerate-api.com/).to_raise(Faraday::ConnectionFailed)
        get convert_url, params: { from: 'USD', to: 'EUR', amount: 100 }

        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)['error']).to eq("Failed to connect to external API")
      end

      it 'returns an internal server error if the external API returns a non-200 status' do
        stub_request(:get, /v6.exchangerate-api.com/).to_return(status: 500)
        get convert_url, params: { from: 'USD', to: 'EUR', amount: 100 }

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq("External API error: 500")
      end

      it 'returns an internal server error if the API response indicates failure' do
        stub_request(:get, /v6.exchangerate-api.com/)
          .to_return(body: @api_error_response, status: 200, headers: { 'Content-Type' => 'application/json' })
        get convert_url, params: { from: 'USD', to: 'INVALID', amount: 100 }

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to include("API response was not successful: unsupported-code")
      end
    end

    context 'with caching' do
      it 'caches the exchange rate and does not call the API on the second request' do
        stub = stub_request(:get, %r{https://v6.exchangerate-api.com/v6/fake_api_key/pair/USD/EUR/1.0})
                 .to_return(body: @valid_response, status: 200, headers: { 'Content-Type' => 'application/json' })

        # First request - should hit the API
        get convert_url, params: { from: 'USD', to: 'EUR', amount: 100 }
        expect(response).to have_http_status(:ok)

        # Second request - should be served from cache
        get convert_url, params: { from: 'USD', to: 'EUR', amount: 50 }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['original_amount']).to eq(50.0)
        expect(json_response['converted_amount']).to eq(42.50) # 50 * 0.85

        # Verify API was called only once
        expect(stub).to have_been_requested.times(1)
      end
    end
  end
end
