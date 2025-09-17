class Api::V1::Auth::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
  protected

  # confirmation のリダイレクト時だけ allow_other_host を許可
  def redirect_options
    { allow_other_host: true }
  end

  def render_create_error_missing_email
    render_error!(
      code: "MISSING_EMAIL",
      field: "email",
      message: I18n.t("devise_token_auth.confirmations.missing_email"),
      status: :unauthorized
    )
  end

  def render_not_found_error
    if Devise.paranoid
      render_create_success
    else
      render_error!(
        code: "USER_NOT_FOUND",
        message: I18n.t("devise_token_auth.confirmations.user_not_found"),
        status: :not_found
      )
    end
  end

  private

  def resource_params
    params.permit(:confirmation_token, :redirect_url)
  end
end
