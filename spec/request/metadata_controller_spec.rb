# spec/requests/metadata_spec.rb
require 'rails_helper'
require 'webmock/rspec'

RSpec.describe "Metadata API", type: :request do
  # Ngắt kết nối mạng thực tế trong toàn bộ test
  before { WebMock.disable_net_connect!(allow_localhost: true) }
  after { WebMock.allow_net_connect! }

  # Dữ liệu HTML giả lập để test
  let(:mock_html) {
    '
    <!DOCTYPE html>
    <html>
    <head>
      <title>Example Domain</title>
      <meta name="description" content="This domain is for use in illustrative examples in documents.">
      <meta property="og:title" content="Open Graph Title">
    </head>
    <body>
    </body>
    </html>
    '
  }

  describe "POST /metadata" do
    
    # --- Test Case 1: Yêu cầu thành công ---
    context "when the URL is valid and fetch is successful" do
      before do
        # Giả lập yêu cầu HTTP GET tới example.com
        stub_request(:get, "https://example.com").to_return(body: mock_html, status: 200)
      end

      it "returns the correct metadata with a 200 OK status" do
        post '/metadata', params: { url: 'https://example.com' }, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response["url"]).to eq('https://example.com')
        expect(json_response["title"]).to eq('Open Graph Title') # Ưu tiên Open Graph
        expect(json_response["description"]).to eq('This domain is for use in illustrative examples in documents.')
      end
    end

    # --- Test Case 2: URL bị thiếu ---
    context "when the URL is missing" do
      it "returns a 400 Bad Request status" do
        post '/metadata', params: { }, as: :json
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq('URL is required')
      end
    end

    # --- Test Case 3: URL có định dạng không hợp lệ ---
    context "when the URL format is invalid" do
      it "returns a 400 Bad Request status" do
        post '/metadata', params: { url: 'not-a-valid-url' }, as: :json
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq('Invalid URL format')
      end
    end

    # --- Test Case 4: Lấy dữ liệu thất bại (lỗi kết nối) ---
    context "when fetching the URL fails due to a network error" do
      before do
        # Giả lập lỗi kết nối mạng
        stub_request(:get, "https://example.com").to_raise(StandardError.new('Mock network error'))
      end

      it "returns a 400 Bad Request status" do
        post '/metadata', params: { url: 'https://example.com' }, as: :json
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include('Failed to fetch URL')
      end
    end
    
    # --- Test Case 5: Lấy dữ liệu thất bại (lỗi HTTP 404) ---
    context "when the URL returns a non-successful HTTP status" do
      before do
        # Giả lập lỗi HTTP 404 Not Found
        stub_request(:get, "https://example.com").to_return(status: 404)
      end

      it "returns a 400 Bad Request status" do
        post '/metadata', params: { url: 'https://example.com' }, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["description"]).to be_nil
      end
    end
  end
end
