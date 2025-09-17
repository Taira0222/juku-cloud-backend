class Api::V1::Auth::SessionsController < DeviseTokenAuth::SessionsController
  protected

  def render_create_error_not_confirmed
    render_error!(
      code: "NOT_CONFIRMED",
      field: "email",
      message:
        I18n.t(
          "devise_token_auth.sessions.not_confirmed",
          email: @resource.email
        ),
      status: :unauthorized
    )
  end

  def render_create_error_bad_credentials
    render_error!(
      code: "BAD_CREDENTIALS",
      message: I18n.t("devise_token_auth.sessions.bad_credentials"),
      status: :unauthorized
    )
  end

  def render_destroy_error
    render_error!(
      code: "USER_NOT_FOUND",
      message: I18n.t("devise_token_auth.sessions.user_not_found"),
      status: :not_found
    )
  end
end
