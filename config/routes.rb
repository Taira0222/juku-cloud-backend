Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      mount_devise_token_auth_for "User", at: "auth"
      mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
    end
  end
end
