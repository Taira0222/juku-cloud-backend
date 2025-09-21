class Api::V1::TeachersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_role!
  before_action :set_school!, only: [:index]

  # GET /api/v1/teachers
  def index
    result = Teachers::IndexQuery.call(current_user, school: @school)
    render json: {
             current_user:
               Teachers::IndexResource.new(result[:current]).serializable_hash,
             teachers:
               result[:teachers].map { |teacher|
                 Teachers::IndexResource.new(teacher).serializable_hash
               }
           }
  end

  # PATCH /api/v1/teachers/:id
  def update
    teacher = User.find(params[:id])
    result = Teachers::Updater.call(teacher:, attrs: update_params)
    render json: { teacher_id: result.id }
  end

  # DELETE /api/v1/teachers/:id
  def destroy
    teacher = Teachers::Validator.call(id: params[:id])
    teacher.destroy!
    head :no_content
  end

  private

  def update_params
    params.permit(
      :id,
      :name,
      :employment_status,
      subject_ids: [],
      available_day_ids: []
    )
  end
end
