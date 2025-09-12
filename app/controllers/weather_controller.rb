class WeatherController < ApplicationController
  require "faraday"

  def index
    city = params[:city]
    if city.blank?
      render json: { error: "City parameter is required" }, status: :bad_request
      return
    end

    begin
      # Sử dụng Rails.cache để lưu trữ kết quả trong 1 giờ
      weather_data = Rails.cache.fetch("weather_#{city}", expires_in: 1.hour) do
        fetch_and_parse_weather_data(city)
      end

      render json: weather_data
    rescue Faraday::ConnectionFailed
      render json: { error: "Failed to connect to external API" }, status: :service_unavailable
    rescue JSON::ParserError
      render json: { error: "Invalid response from external API" }, status: :service_unavailable
    rescue StandardError => e
      render json: { error: e.message }, status: :service_unavailable
    end
  end

  # GET /weather/bulk?cities=Tokyo,Osaka
  def bulk
    cities = params[:cities].to_s.split(",").map(&:strip)
    results = []

    cities.each do |city|
      # Sử dụng Rails.cache để lưu trữ kết quả trong 1 giờ
      weather_data = Rails.cache.fetch("weather_#{city}", expires_in: 1.hour) do
        begin
          fetch_and_parse_weather_data(city)
        rescue StandardError
          nil
        end
      end
      results << weather_data unless weather_data.nil?
    end

    render json: results
  end

  private
  # Phương thức trợ giúp để gọi API và xử lý dữ liệu thô
  def fetch_and_parse_weather_data(city)
    api_key = ENV["OPENWEATHER_API_KEY"]
    if api_key.blank?
      raise "API key is not configured"
    end

    response = Faraday.get("https://api.openweathermap.org/data/2.5/weather?q=#{city}&appid=#{api_key}&units=metric")

    if response.status != 200
      raise "External API error: #{response.status}"
    end

    data = JSON.parse(response.body)


    {
      city: data["name"],
      temp_celsius: data["main"]["temp"],
      description: data["weather"][0]["description"]
    }
  end
end
