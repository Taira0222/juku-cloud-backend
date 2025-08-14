require "rails_helper"

RSpec.describe "User Registrations", type: :request do
  # テスト前にユーザーを作成
  let!(:confirmed_user) { create(:user) }
  let!(:school) { create(:school) }
  let!(:invite) { create(:invite, school: school, raw_token: "valid_token") }

  describe "POST /api/v1/auth" do
    it "successfully registers a new user and sends a confirmation email" do
      post "/api/v1/auth",
           params: {
             name: "First User",
             email: "first@example.com",
             password: "password",
             password_confirmation: "password",
             token: "valid_token"
           }
      mail = ActionMailer::Base.deliveries.last
      expect(response).to have_http_status(:success)
      expect(mail.to).to include("first@example.com")
      expect(mail.subject).to eq("メールアドレス確認メール")
      MAIL_BODY = [
        "アカウント登録の確認",
        "First Userさん、こんにちは！",
        "アカウント登録を完了するため、",
        "以下のリンクをクリックしてください。URLは24時間有効です。",
        "メールアドレスを確認する"
      ]
      MAIL_BODY.each { |line| expect(mail.body.encoded).to include(line) }
      # invite が使用済みになっているか確認
      invite.reload
      expect(invite.used_at).to be_present
    end

    it "returns an error when passwords do not match" do
      post "/api/v1/auth",
           params: {
             name: "Second User",
             email: "second@example.com",
             password: "password",
             password_confirmation: "wrong_password",
             token: "valid_token"
           }
      expect(response).to have_http_status(:unprocessable_entity)
      invite.reload
      expect(invite.used_at).not_to be_present
    end

    it "returns an error when email is already taken" do
      post "/api/v1/auth",
           params: {
             name: "Third User",
             email: confirmed_user.email,
             password: "password",
             password_confirmation: "password",
             token: "valid_token"
           }
      expect(response).to have_http_status(:unprocessable_entity)
      invite.reload
      expect(invite.used_at).not_to be_present
    end

    it "returns an error when email is invalid" do
      post "/api/v1/auth",
           params: {
             name: "Fourth User",
             email: "invalid_email",
             password: "password",
             password_confirmation: "password",
             token: "valid_token"
           }
      expect(response).to have_http_status(:unprocessable_entity)
      invite.reload
      expect(invite.used_at).not_to be_present
    end

    it "returns an error when token is invalid" do
      post "/api/v1/auth",
           params: {
             name: "Fifth User",
             email: "fifth@example.com",
             password: "password",
             password_confirmation: "password",
             token: "invalid_token"
           }
      expect(response).to have_http_status(:unprocessable_entity)
      invite.reload
      expect(invite.used_at).not_to be_present
    end

    it "returns an error when token is missing" do
      post "/api/v1/auth",
           params: {
             name: "Sixth User",
             email: "sixth@example.com",
             password: "password",
             password_confirmation: "password"
           }
      expect(response).to have_http_status(:unprocessable_entity)
      invite.reload
      expect(invite.used_at).not_to be_present
    end
  end
end
