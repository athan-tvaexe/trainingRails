# app/controllers/tasks_controller.rb
class TasksController < ApplicationController
  # GET /tasks
  # Lấy tất cả task, có thể lọc theo trạng thái hoàn thành.
  def index
    tasks = Task.all
    if params[:completed].present?
      tasks = tasks.where(completed: params[:completed] == "true")
    end
    render json: tasks
  end

  # POST /tasks
  # Tạo task mới với completed mặc định là false.
  def create
    task = Task.new(task_params)
    task.completed = false
    if task.save
      render json: task, status: :created
    else
      render json: { errors: task.errors.full_messages }, status: :bad_request
    end
  end

  # PATCH /tasks/:id
  # Cập nhật task theo ID.
  def update
    task = Task.find_by(id: params[:id])
    return render json: { errors: [ "Task not found" ] }, status: :not_found unless task

    if task.update(task_params)
      render json: task
    else
      render json: { errors: task.errors.full_messages }, status: :bad_request
    end
  end

  # DELETE /tasks/:id
  # Xóa task theo ID.
  def destroy
    task = Task.find_by(id: params[:id])
    return render json: { errors: [ "Task not found" ] }, status: :not_found unless task

    task.destroy
    head :no_content
  end

  private

  # Strong Parameters để đảm bảo an toàn.
  def task_params
    params.require(:task).permit(:title, :due_date, :completed)
  end
end
