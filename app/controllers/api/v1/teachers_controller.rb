class Api::V1::TeachersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_role!
  before_action :set_school!, only: [ :index ]
  before_action :set_teacher!, only: [ :destroy ]
  before_action :ensure_not_admin_deletion, only: [ :destroy ]

  def index
    result = Teachers::IndexQuery.call(current_user, school: @school)
    render json: Teachers::IndexPresenter.new(result).as_json, status: :ok
  end
  # DELETE /api/v1/teachers/:id
  def destroy
    if @teacher.destroy
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

  def set_teacher!
    @teacher = User.find(params[:id])
  end

  # 誤ってadminを削除できないようにする
  def ensure_not_admin_deletion
    if @teacher.admin_role?
      render json: {
               error: I18n.t("teachers.errors.delete.admin")
             },
             status: :forbidden
    end
  end
end
