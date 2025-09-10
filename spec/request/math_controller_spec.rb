# spec/controllers/math_controller_spec.rb
require 'rails_helper'

RSpec.describe MathController, type: :controller do
  describe "POST #sum_numbers" do
    context "when numbers is sent as a Ruby array (as: :json)" do
      it "returns a successful response with the correct sum and average for integers" do
        numbers = [ 1, 2, 3, 4, 5 ]
        post :sum_numbers, params: { numbers: numbers }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['sum']).to eq(numbers.sum)
        expect(json_response['average']).to eq(numbers.sum.to_f / numbers.length)
      end

      it "handles large numbers correctly" do
        numbers = [ 1000000000, 2000000000, 3000000000 ]
        post :sum_numbers, params: { numbers: numbers }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['sum']).to eq(numbers.sum)
        expect(json_response['average']).to eq(numbers.sum.to_f / numbers.length)
      end

      it "handles an empty array" do
        numbers = []
        post :sum_numbers, params: { numbers: numbers }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['sum']).to eq(0)
        expect(json_response['average']).to eq(0)
      end

      it "handles numbers with decimals" do
        numbers = [ 1.5, 2.5, 3 ]
        post :sum_numbers, params: { numbers: numbers }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['sum']).to eq(numbers.sum)
        expect(json_response['average']).to eq(numbers.sum.to_f / numbers.length)
      end
    end

    context "when numbers is sent as a JSON string" do
      it "returns a successful response with the correct sum and average for integers" do
        numbers_json = "[1, 2, 3, 4, 5]"
        numbers_array = JSON.parse(numbers_json)
        post :sum_numbers, params: { numbers: numbers_json }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['sum']).to eq(numbers_array.sum)
        expect(json_response['average']).to eq(numbers_array.sum.to_f / numbers_array.length)
      end

      it "returns a successful response with the correct sum and average for decimals" do
        numbers_json = "[1.5, 2.5, 3]"
        numbers_array = JSON.parse(numbers_json)
        post :sum_numbers, params: { numbers: numbers_json }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['sum']).to eq(numbers_array.sum)
        expect(json_response['average']).to eq(numbers_array.sum.to_f / numbers_array.length)
      end

      it "returns a 400 Bad Request if the JSON string is malformed" do
        post :sum_numbers, params: { numbers: '{"not": "an array"}' }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq("Invalid input. Please provide an array of numbers.")
      end
    end

    context "with other invalid input" do
      it "returns a 400 Bad Request if 'numbers' is not an array" do
        post :sum_numbers, params: { numbers: "not an array" }, as: :json
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq("Invalid input. Please provide an array of numbers.")
      end

      it "returns a 400 Bad Request if the array contains non-numeric values" do
        post :sum_numbers, params: { numbers: [ 1, 2, "a", 4 ] }, as: :json
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq("Invalid input. Please provide an array of numbers.")
      end

      it "returns a 400 Bad Request if 'numbers' is missing" do
        post :sum_numbers, params: {}, as: :json
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq("Invalid input. Please provide an array of numbers.")
      end
    end
  end
end
