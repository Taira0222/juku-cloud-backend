require "rails_helper"

RSpec.describe "Api::V1::Invites", type: :request do
  describe "GET /show" do
    let!(:invite) { create(:invite) }

    it "returns a successful response with school name" do
      get api_v1_invite_path(token: invite.raw_token)
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["school_name"]).to eq(invite.school.name)
    end

    it "returns not found for invalid token" do
      get api_v1_invite_path(token: "invalid_token")
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body, symbolize_names: true)
      errors = json_response[:errors].first
      expect(errors[:message]).to eq(I18n.t("invites.errors.invalid"))
    end
  end

  describe "POST /create" do
    let!(:admin_user) { create(:admin_user) }
    let!(:school) { create(:school, owner: admin_user) }

    it "creates an invite token" do
      post_with_auth api_v1_invites_path, admin_user
      json_response = JSON.parse(response.body)

      expect(response).to have_http_status(:created)
      expect(json_response["token"]).to be_present
    end

    it "returns an error if the user is not an admin" do
      admin_user.update(role: :teacher)
      post_with_auth api_v1_invites_path, admin_user
      expect(response).to have_http_status(:forbidden)
    end
  end
end
