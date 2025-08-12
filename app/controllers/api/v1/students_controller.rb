class Api::V1::StudentsController < ApplicationController
  before_action :set_school!

  def index
    if current_user.teacher_role?
      @students =
        Student.eager_load(:users).where(school: current_user.school.id)
    else
      @students = Student.eager_load(:users).where(school: @school)
    end
    render json: @students.as_json(include: :users), status: :ok
  end

  private

  def set_school!
    return if current_user.teacher_role?
    @school = School.find_by(owner_id: current_user.id)
    return if @school

    # 404
    render json: { error: "学校が見つかりません" }, status: :not_found
    nil
  end
end
