class Api::V1::StudentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!

  def index
    @students = Student.where(school: @school).preload(:teachers)
    render json:
             @students.map { |s|
               {
                 name: s.name,
                 student_code: s.student_code,
                 school_stage: s.school_stage,
                 grade: s.grade,
                 status: s.status,
                 teachers:
                   s.teachers.uniq(&:id).map { |t| t.slice(:id, :name, :email) }
               }
             },
           status: :ok
  end
end
