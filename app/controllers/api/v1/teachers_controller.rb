class Api::V1::TeachersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_role!
  before_action :set_school!, only: [ :index ]

  # GET /api/v1/teachers
  def index
    result = Teachers::IndexQuery.call(current_user, school: @school)
    render json: {
             current_user:
               Teachers::IndexResource.new(result[:current]).serializable_hash,
             teachers:
               Teachers::IndexResource.new(result[:teachers]).serializable_hash
           }
  end

  # PATCH /api/v1/teachers/:id
  def update
    teacher = User.find(params[:id])
    result = Teachers::Updater.call(teacher:, attrs: update_params)

    if result.ok?
      render json: { teacher_id: result.teacher.id }, status: :ok
    else
      # errors は配列
      render json: { errors: result.errors }, status: :unprocessable_content
    end
  end

  # DELETE /api/v1/teachers/:id
  def destroy
    validation = Teachers::Validator.call(id: params[:id])
    # バリデーションエラー時の処理
    unless validation.ok?
      return render json: { error: validation.error }, status: validation.status
    end

    if validation.teacher.destroy
      # 成功時は204 No Contentを返す
      head :no_content
    else
      # 422 エラー
      render json: {
               error: I18n.t("teachers.errors.delete.failure")
             },
             status: :unprocessable_content
    end
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
