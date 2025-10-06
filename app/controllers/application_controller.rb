class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include DeviseHackFakeSession
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

  def ensure_student_access!
    raw_id = params[:student_id].presence || params[:id].presence
    # 空 or 非数値は 400
    if raw_id.blank? || !raw_id.to_s.match?(/\A\d+\z/)
      raise ActionController::BadRequest
    end

    # 管理者は学校に所属する生徒ならOK
    if current_user.admin_role?
      allowed = @school.students.exists?(id: raw_id.to_i)
      unless allowed
        raise ActiveRecord::RecordNotFound,
              I18n.t("application.errors.not_found_student")
      end
    else # 教員は担当している生徒のみ
      allowed = current_user.students.exists?(id: raw_id.to_i)
      unless allowed
        raise ForbiddenError, I18n.t("application.errors.unable_operate")
      end
    end
  end
end
