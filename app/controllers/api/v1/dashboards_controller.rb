class Api::V1::DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!
  before_action :ensure_student_access!

  # GET /api/v1/dashboards/:id
  def show
    student = Dashboards::ShowQuery.call(school: @school, id: params[:id])
    render json: Dashboards::ShowResource.new(student).serializable_hash,
           status: :ok
  end

  private

  # 担当していない生徒の情報を見ようとした場合は403を返す
  def ensure_student_access!
    return if current_user.admin_role?

    allowed = current_user.students.exists?(id: params[:id])
    unless allowed
      raise ForbiddenError, I18n.t("dashboard.errors.unable_operate")
    end
  end
end
