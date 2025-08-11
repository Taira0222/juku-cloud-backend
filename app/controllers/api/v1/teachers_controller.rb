class Api::V1::TeachersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_role!
  before_action :set_school!

  def index
    # ここから初めてプリロード（成功パスでのみ実行される）
    result = Teachers::IndexQuery.call(current_user, school: @school)
    render json: Teachers::IndexPresenter.new(result).as_json, status: :ok
  end

  private

  # 例外を投げるので、! をつけておく
  def require_admin_role!
    unless current_user.admin_role?
      # 403
      render json: { error: "講師はこの操作を行うことができません" }, status: :forbidden
    end
  end

  def set_school!
    @school = School.find_by(owner_id: current_user.id)
    return if @school

    # 404
    render json: { error: "学校が見つかりません" }, status: :not_found
  end
end
