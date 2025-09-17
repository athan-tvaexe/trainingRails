class ScoresController < ApplicationController
  def create
    # Tìm kiếm một bản ghi Score với user đã cho.
    score = Score.find_by(user: score_params[:user])

    # Sử dụng một biến để theo dõi hành động là tạo mới hay cập nhật
    is_new_record = score.nil?

    if is_new_record
      # Tạo một bản ghi mới nếu người dùng chưa tồn tại
      score = Score.new(score_params)
    else
      # Cộng dồn điểm nếu người dùng đã tồn tại
      score.points += score_params[:points]
    end

    if score.save
      if is_new_record
        render json: score, status: :created # Trả về 201 nếu là bản ghi mới
      else
        render json: score, status: :ok     # Trả về 200 nếu là cập nhật
      end
    else
      render json: { errors: score.errors.full_messages }, status: :bad_request
    end
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  end

  def leaderboard
    limit = params[:limit].to_i
    limit = 10 if limit <= 0

    # Sắp xếp trực tiếp các bản ghi theo điểm số giảm dần
    leaderboard_data = Score.order(points: :desc).limit(limit)

    # Chuyển đổi định dạng dữ liệu
    formatted_data = leaderboard_data.map do |score|
      { user: score.user, total_points: score.points }
    end

    render json: formatted_data, status: :ok
  end

  private

  # Sử dụng Strong Parameters để bảo vệ dữ liệu
  def score_params
    params.require(:score).permit(:user, :points)
  end
end
