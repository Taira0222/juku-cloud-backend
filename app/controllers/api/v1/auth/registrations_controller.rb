class Api::V1::Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  def create
    super do |user|
      user.role = :teacher
    end
  end

  protected
    # 会員登録の際にparams を追加する場合
    def sign_up_params
      params.permit(:name, :email, :password, :password_confirmation)
    end

    # アカウント更新の際にparams を追加する場合
    def account_update_params
      params.permit(:name, :grade, :school_stage, :graduated_university)
    end
end
