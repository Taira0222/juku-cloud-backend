require "rails_helper"

RSpec.describe "User Sessions", type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:user) { create(:user) }

  describe "POST /api/v1/auth/sign_in" do
    context "with valid credentials" do
      it "successfully logs in with valid credentials" do
        sign_in(admin_user)
        expect(response).to have_http_status(:success)
        expect(response.headers).to include(
          "access-token",
          "client",
          "uid",
          "expiry",
          "token-type"
        )
        sign_in(user)
        expect(response).to have_http_status(:success)
        expect(response.headers).to include(
          "access-token",
          "client",
          "uid",
          "expiry",
          "token-type"
        )
      end
    end

    context "with invalid credentials" do
      it "fails due to unconfirmed email" do
        unconfirmed_user = create(:user, :unconfirmed)
        sign_in(unconfirmed_user)
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body, symbolize_names: true)
        error = json_response[:errors].first
        expect(error[:code]).to eq("NOT_CONFIRMED")
        expect(error[:field]).to eq("email")
        expect(error[:message]).to include(
          I18n.t(
            "devise_token_auth.sessions.not_confirmed",
            email: unconfirmed_user.email
          )
        )
      end

      it "fails due to bad credentials" do
        post "/api/v1/auth/sign_in",
             params: {
               email: user.email,
               password: "wrong_password"
             }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body, symbolize_names: true)
        error = json_response[:errors].first
        expect(error[:code]).to eq("BAD_CREDENTIALS")
        expect(error[:message]).to eq(
          I18n.t("devise_token_auth.sessions.bad_credentials")
        )
      end
    end
  end

  describe "DELETE /api/v1/auth/sign_out" do
    it "successfully logs out" do
      admin_auth_token = sign_in(admin_user)
      sign_out(admin_auth_token)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('"success":true')
      user_auth_token = sign_in(user)
      sign_out(user_auth_token)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('"success":true')
    end

    it "fails to log out when not logged in" do
      sign_out({})
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body, symbolize_names: true)
      error = json_response[:errors].first
      expect(error[:code]).to eq("USER_NOT_FOUND")
      expect(error[:message]).to eq(
        I18n.t("devise_token_auth.sessions.user_not_found")
      )
    end
  end
end
