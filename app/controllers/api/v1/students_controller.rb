class Api::V1::StudentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!
  before_action :require_admin_role!, only: %i[create update destroy]

  # GET /api/v1/students
  def index
    students =
      Students::IndexQuery.call(
        school: @school,
        index_params: index_params,
        current_user: current_user
      )

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

  # POST /api/v1/students
  def create
    student =
      Students::CreateService.call(
        school: @school,
        create_params: create_params
      )
    render json: Students::CreateResource.new(student).serializable_hash,
           status: :created
  end

  # PATCH/PUT /api/v1/students/:id
  def update
    student =
      Students::Updater.call(school: @school, update_params: update_params)
    render json: Students::UpdateResource.new(student).serializable_hash,
           status: :ok
  end

  # DELETE /api/v1/students/:id
  def destroy
    student = Students::Validator.call(id: params[:id])
    student.destroy!
    head :no_content
  end

  private

  def index_params
    params.permit(:searchKeyword, :school_stage, :grade, :page, :perPage)
  end

  def base_params
    [
      :name,
      :status,
      :school_stage,
      :grade,
      :joined_on,
      :desired_school,
      {
        subject_ids: [],
        available_day_ids: [],
        assignments: %i[teacher_id subject_id day_id]
      }
    ]
  end

  def create_params
    params.permit(*base_params)
  end

  def update_params
    params.permit(:id, *base_params)
  end
end
