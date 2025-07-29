class Api::V1::Auth::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
  protected
    # confirmation のリダイレクト時だけ allow_other_host を許可
    def redirect_options
      { allow_other_host: true }
    end

  private

    def resource_params
      params.permit(:confirmation_token, :redirect_url)
    end
end
