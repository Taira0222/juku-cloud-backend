class Api::V1::TeachersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_role!
  before_action :set_school!, only: [ :index ]

  def index
    result = Teachers::IndexQuery.call(current_user, school: @school)
    render json: Teachers::IndexPresenter.new(result).as_json, status: :ok
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
end
