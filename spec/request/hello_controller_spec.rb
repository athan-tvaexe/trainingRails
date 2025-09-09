require 'rails_helper'

RSpec.describe "Hello API", type: :request do
  # The `get` method in a request spec requires a full path string.
  describe "GET /hello" do
    it "returns a successful response with the correct JSON" do
      get "/hello"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ "message" => "Hello, World!" })
    end
  end

  describe "GET /greet" do
    # Tạo một mảng gồm 10 chuỗi ngẫu nhiên để test
    random_names = 10.times.map { SecureRandom.hex(5) }

    context "with a name parameter and a language" do
      random_names.each do |name|
        it "returns a Japanese greeting when lang=ja" do
          get "/greet", params: { name: name, lang: 'ja' }
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["greeting"]).to eq("こんにちは、#{name}さん！")
        end

        it "returns an English greeting when lang=en" do
          get "/greet", params: { name: name, lang: 'en' }
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["greeting"]).to eq("Hello, #{name}!")
        end

        it "defaults to an English greeting when lang is not provided" do
          get "/greet", params: { name: name }
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["greeting"]).to eq("Hello, #{name}!")
        end
      end
    end

    context "without a name parameter" do
      it "returns a bad request status with an error message" do
        get "/greet"
        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Name is required.")
      end
    end

    context "without a name parameter and language is japanese" do
      it "returns a bad request status with an error message" do
        get "/greet", params: { lang: 'ja' }
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("名前は必須です。")
      end
    end
  end
end
