class Api::V1::Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  # POST /api/v1/auth デフォルトのcreateアクションを使用
  def create
    extract_token!

    @invite = Invites::Validator.call(@raw_token)
    @school = @invite.school

    super
    # レスポンス完了、成功、DBに保存できた場合
    @invite.consume! if @resource&.persisted?
  end

  protected

  def build_resource
    super
    @resource.role = :teacher
    @resource.school = @school
  end

  # 会員登録の際にparams を追加する場合
  def sign_up_params
    params.permit(:name, :email, :password, :password_confirmation)
  end

  def render_create_error
    render_model_errors!(
      @resource,
      status: :unprocessable_content,
      default_code: "REGISTRATION_FAILED"
    )
  end

  def render_update_error
    render_model_errors!(
      @resource,
      status: :unprocessable_content,
      default_code: "UPDATE_FAILED"
    )
  end

  # --- 以下はupdate やdestroy アクション実装時に使用する可能性があるメソッド ---
  def render_update_error_user_not_found
    render_error!(
      code: "USER_NOT_FOUND",
      message: I18n.t("devise_token_auth.registrations.user_not_found"),
      status: :not_found
    )
  end

  def render_destroy_error
    render_error!(
      code: "ACCOUNT_NOT_FOUND",
      message:
        I18n.t("devise_token_auth.registrations.account_to_destroy_not_found"),
      status: :not_found
    )
  end

  private

  # token をparamsから抽出
  def extract_token!
    @raw_token = params.delete(:token)
    unless @raw_token.present?
      raise ActiveRecord::RecordNotFound, I18n.t("invites.errors.invalid")
    end
  end

  def render_invalid_invite(e)
    @resource = resource_class.new(sign_up_params)
    @resource.valid?
    @resource.errors.add(:token, e.message)
    render_create_error
  end
end
