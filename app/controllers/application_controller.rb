class ApplicationController < ActionController::API
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action do
    I18n.locale = :ja
  end
  include DeviseTokenAuth::Concerns::SetUserByToken
  include DeviseHackFakeSession

  private
    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :role ])
      devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :role, :grade,
                                                                :school_stage, :graduated_university ])
    end
end
