class MathController < ApplicationController
    def sum_numbers
    # 1. Get the 'numbers' array from the request body
    numbers = params[:numbers]

    # Handle cases where the input is a JSON string
    if numbers.is_a?(String)
      begin
        numbers = JSON.parse(numbers)
      rescue JSON::ParserError
        # If parsing fails, it's a format error
        render json: { error: "Invalid input. Please provide an array of numbers." }, status: :bad_request
        return
      end
    end

    # 2. Validate input (requires 400 Bad Request)
    unless numbers.is_a?(Array) && numbers.all? { |n| n.is_a?(Numeric) }
      render json: { error: "Invalid input. Please provide an array of numbers." }, status: :bad_request
      return
    end

    # 3. Calculate the sum and average, then return the result
    total_sum = numbers.sum

    if numbers.empty?
      average = 0
    else
      average = total_sum.to_f / numbers.length
    end

    render json: { sum: total_sum, average: average }, status: :ok
  end
end
