require 'rails_helper'

# Note: While controller specs work, the Rails community and RSpec team
# now recommend using request specs for testing controllers. Request specs
# provide a more realistic test of the entire request/response cycle,
# including routing.
RSpec.describe HelloController, type: :controller do
  describe "GET #index" do
    it "returns a successful response with the correct JSON" do
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ "message" => "Hello, World!" })
    end
  end
end
