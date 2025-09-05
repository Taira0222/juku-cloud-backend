class Api::V1::StudentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!
  before_action :require_admin_role!, only: %i[create]

  def index
    students =
      Students::IndexQuery.call(school: @school, index_params: index_params)
    render json: {
             students: Students::IndexResource.new(students).serializable_hash,
             meta: {
               total_pages: students.total_pages,
               total_count: students.total_count,
               current_page: students.current_page,
               per_page: students.limit_value
             }
           }
  end

  def create
    result =
      Students::CreateService.call(
        school: @school,
        create_params: create_params
      )
    if result.ok?
      student = result.value
      render json: Students::CreateResource.new(student).serializable_hash,
             status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_content
    end
  end

  private

  def index_params
    params.permit(:searchKeyword, :school_stage, :grade, :page, :perPage)
  end

  def create_params
    params.permit(
      :name,
      :status,
      :school_stage,
      :grade,
      :joined_on,
      :desired_school,
      subject_ids: [],
      available_day_ids: [],
      assignments: %i[teacher_id subject_id day_id]
    )
  end
end
