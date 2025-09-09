class HelloController < ApplicationController
  def index
    render json: { message: "Hello, World!" }
  end

  def greet
    name = params[:name]
    if name.blank?
      render json: { error: "Name parameter is missing" }, status: :bad_request
    else
      render json: { greeting: "Hello, #{name}!" }
    end
  end
end
