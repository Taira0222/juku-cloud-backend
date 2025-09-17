require "rails_helper"

RSpec.describe "User Sessions", type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:user) { create(:user) }

  describe "POST /api/v1/auth/sign_in" do
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
      expect(response.body).to include("ユーザーが見つかりませんでした。")
    end
  end
end
