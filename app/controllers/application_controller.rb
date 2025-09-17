class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include DeviseHackFakeSession
  include ResultRenderable
  include ApiErrorRenderable # 共通のエラーレスポンス処理
  include ErrorHandlers # 外部・システムエラーのハンドリング

  protected

  def current_user
    current_api_v1_user
  end

  def authenticate_user!
    authenticate_api_v1_user!
  end

  def user_signed_in?
    api_v1_user_signed_in?
  end

  private

  def set_school!
    if current_user&.admin_role?
      @school = School.find_by(owner_id: current_user.id)
    else
      @school = current_user.school
    end

    unless @school
      raise ActiveRecord::RecordNotFound,
            I18n.t("application.errors.not_found_school")
    end
  end

  def require_admin_role!
    unless current_user.admin_role?
      raise ForbiddenError, I18n.t("application.errors.teacher_unable_operate")
    end
  end
end
