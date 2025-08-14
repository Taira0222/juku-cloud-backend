class ApplicationController < ActionController::API
  before_action { I18n.locale = :ja }
  include DeviseTokenAuth::Concerns::SetUserByToken
  include DeviseHackFakeSession

  protected

  # DeviseTokenAuth用の認証メソッドエイリアス
  alias_method :current_user, :current_api_v1_user
  alias_method :authenticate_user!, :authenticate_api_v1_user!
  alias_method :user_signed_in?, :api_v1_user_signed_in?

  private

  # 例外を投げるので、! をつけておく
  def set_school!
    if current_user.admin_role?
      @school = School.find_by(owner_id: current_user.id)
      raise ActiveRecord::RecordNotFound unless @school.present?
    else
      @school = current_user.school
      raise ActiveRecord::RecordNotFound unless @school.present?
    end
  rescue ActiveRecord::RecordNotFound
    # 404
    render json: {
             error: I18n.t("application.errors.not_found_school")
           },
           status: :not_found
    nil
  end

  def require_admin_role!
    unless current_user.admin_role?
      # 403
      render json: {
               error: I18n.t("application.errors.teacher_unable_operate")
             },
             status: :forbidden
      nil
    end
  end
end
