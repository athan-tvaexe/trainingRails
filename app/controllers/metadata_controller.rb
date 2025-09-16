require 'net/http'
require 'nokogiri'
require 'uri'

class MetadataController < ApplicationController
#   # Bỏ qua xác thực CSRF token cho API endpoint này
#   skip_before_action :verify_authenticity_token

  def create
    url_string = params[:url]

    # Kiểm tra URL có tồn tại và hợp lệ không
    unless url_string.present?
      render json: { error: 'URL is required' }, status: :bad_request and return
    end

    begin
      uri = URI.parse(url_string)
      # Chỉ cho phép các giao thức HTTP hoặc HTTPS
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        render json: { error: 'Invalid URL format' }, status: :bad_request and return
      end

      # Lấy nội dung HTML từ URL
      response = Net::HTTP.get_response(uri)
      
      # Xử lý trường hợp không thành công (ví dụ: lỗi 404, 500)
      unless response.is_a?(Net::HTTPSuccess)
        render json: { error: "Failed to fetch URL: #{response.code} #{response.message}" }, status: :bad_request and return
      end
      
      html_content = response.body
      
    rescue URI::InvalidURIError
      render json: { error: 'Invalid URL format' }, status: :bad_request
      return
    rescue StandardError => e
      # Bắt các lỗi kết nối khác như timeout, host không tồn tại...
      render json: { error: "Failed to fetch URL: #{e.message}" }, status: :bad_request
      return
    end
    

    # Phân tích cú pháp HTML và trích xuất dữ liệu
    doc = Nokogiri::HTML(html_content)

    # Trích xuất tiêu đề (ưu tiên Open Graph)
    og_title = doc.at('meta[property="og:title"]')&.[]('content')
    title = og_title.presence || doc.at('title')&.text
    
    # Trích xuất mô tả (ưu tiên Open Graph)
    og_description = doc.at('meta[property="og:description"]')&.[]('content')
    description = og_description.presence || doc.at('meta[name="description"]')&.[]('content')

    # Trả về kết quả JSON
    render json: {
      url: url_string,
      title: title,
      description: description
    }, status: :ok

  end
end
