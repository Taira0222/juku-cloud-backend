class ApplicationController < ActionController::API
  before_action do
    I18n.locale = :ja
  end
  include DeviseTokenAuth::Concerns::SetUserByToken
  include DeviseHackFakeSession

  protected
    # DeviseTokenAuth用の認証メソッドエイリアス
    alias_method :current_user, :current_api_v1_user
    alias_method :authenticate_user!, :authenticate_api_v1_user!
    alias_method :user_signed_in?, :api_v1_user_signed_in?
end
