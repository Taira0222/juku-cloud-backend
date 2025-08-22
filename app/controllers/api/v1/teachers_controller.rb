class Api::V1::TeachersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_role!
  before_action :set_school!, only: [ :index ]

  # GET /api/v1/teachers
  def index
    result = Teachers::IndexQuery.call(current_user, school: @school)
    render json: Teachers::IndexPresenter.new(result).as_json, status: :ok
  end

  # PATCH /api/v1/teachers/:id
  def update
    teacher = User.find(params[:id])

    base_attrs, subject_ids, day_ids, student_ids =
      extract_update_payload(update_params)

    ActiveRecord::Base.transaction do
      teacher.update!(base_attrs) unless base_attrs.empty?

      # 多対多: 差し替え（空配列なら全解除）
      teacher.class_subject_ids = subject_ids if subject_ids
      teacher.available_day_ids = day_ids if day_ids
      teacher.student_ids = student_ids if student_ids
    end

    render json: { teacher_id: teacher.reload.id }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
             error: I18n.t("teachers.errors.not_found")
           },
           status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: {
             error: e.record.errors.full_messages
           },
           status: :unprocessable_content
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
      :name,
      :employment_status,
      subject_ids: [],
      available_day_ids: [],
      student_ids: []
    )
  end

  def extract_update_payload(p)
    base = p.slice(:name, :employment_status).compact_blank
    subject_ids = p[:subject_ids]
    day_ids = p[:available_day_ids]
    student_ids = p[:student_ids]
    [ base, subject_ids, day_ids, student_ids ]
  end
end
