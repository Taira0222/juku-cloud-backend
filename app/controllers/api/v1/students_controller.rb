class Api::V1::StudentsController < ApplicationController
  def index
    @school = School.find_by(owner_id: current_user.id)
    if @school.nil?
      render json: { error: "学校が見つかりません" }, status: :not_found
      return
    end
    @students = Student.eager_load(:users).where(school: @school)
    render json: @students.as_json(include: :users), status: :ok
  end
end
