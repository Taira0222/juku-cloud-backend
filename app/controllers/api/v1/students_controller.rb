class Api::V1::StudentsController < ApplicationController
  before_action :authenticate_user!
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
end
