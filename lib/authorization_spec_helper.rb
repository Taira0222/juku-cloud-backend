module AuthorizationSpecHelper
  def sign_in(user)
    post "/api/v1/auth/sign_in", params: { email: user.email, password: "password" }, as: :json
    response.headers.slice("access-token", "client", "uid", "expiry", "token-type")
  end

  def sign_out(auth_token)
    delete "/api/v1/auth/sign_out", headers: auth_token, as: :json
  end
end
