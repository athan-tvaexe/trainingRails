

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
    # `SecureRandom.hex` là một phương thức tuyệt vời để tạo chuỗi ngẫu nhiên và duy nhất.
    random_names = 10.times.map { SecureRandom.hex(5) }

    context "with various random name parameters" do
      random_names.each do |name|
        it "returns a greeting for the name '#{name}'" do
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
        expect(json_response["error"]).to eq("Name parameter is missing")
      end
    end
  end
end