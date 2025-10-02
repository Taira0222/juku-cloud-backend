Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      mount_devise_token_auth_for "User",
                                  at: "auth",
                                  controllers: {
                                    confirmations: "api/v1/auth/confirmations",
                                    registrations: "api/v1/auth/registrations",
                                    sessions: "api/v1/auth/sessions"
                                  }
      resources :teachers, only: %i[index update destroy]
      resources :invites, only: %i[show create], param: :token
      resources :students, only: %i[index create update destroy]
      resources :dashboards, only: %i[show]
      resources :lesson_notes, only: %i[index create update destroy]
      resources :student_traits, only: %i[index create update destroy]
      if Rails.env.development?
        mount LetterOpenerWeb::Engine, at: "/letter_opener"
      end
    end
  end
end
