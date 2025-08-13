Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      mount_devise_token_auth_for "User",
                                  at: "auth",
                                  controllers: {
                                    confirmations: "api/v1/auth/confirmations",
                                    registrations: "api/v1/auth/registrations"
                                  }
      resources :teachers
      resources :invites, only: %i[show create]
      resources :students
      if Rails.env.development?
        mount LetterOpenerWeb::Engine, at: "/letter_opener"
      end
    end
  end
end
