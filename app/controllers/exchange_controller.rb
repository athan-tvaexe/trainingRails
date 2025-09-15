# app/controllers/exchange_controller.rb
require "faraday"

class ExchangeController < ApplicationController
  def convert
    from_currency = params[:from].presence
    to_currency = params[:to].presence

    # Corrected line to default amount to 1.0 if not provided
    original_amount = (params[:amount].presence || 1.0).to_f

    if from_currency.blank? || to_currency.blank?
      render json: { error: "'from' and 'to' are required parameters" }, status: :bad_request
      return
    end

    if original_amount <= 0
      render json: { error: "amount must be a positive number" }, status: :bad_request
      return
    end

    begin
      cache_key = "rate_#{from_currency}_to_#{to_currency}"

      exchange_rate = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        fetch_exchange_rate(from_currency, to_currency)
      end

      converted_amount = original_amount * exchange_rate

      render json: {
        from: from_currency,
        to: to_currency,
        original_amount: original_amount,
        converted_amount: converted_amount.round(2),
        rate: exchange_rate.round(4)
      }

    rescue Faraday::ConnectionFailed
      render json: { error: "Failed to connect to external API" }, status: :service_unavailable
    rescue JSON::ParserError
      render json: { error: "Invalid response from external API" }, status: :service_unavailable
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private

  def fetch_exchange_rate(from_currency, to_currency)
    api_key = ENV["EXCHANGE_API_KEY"]
    if api_key.blank?
      raise "API key is not configured"
    end

    response = Faraday.get("https://v6.exchangerate-api.com/v6/#{api_key}/pair/#{from_currency}/#{to_currency}/#{1.0}")

    unless response.success?
      raise "External API error: #{response.status}"
    end

    data = JSON.parse(response.body)

    if data["result"] != "success"
      raise "API response was not successful: #{data['error-type']}"
    end

    data["conversion_rate"]
  end
end
