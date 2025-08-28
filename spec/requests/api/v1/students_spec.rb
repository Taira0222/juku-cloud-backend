require "rails_helper"

RSpec.describe "Api::V1::Students", type: :request do
  describe "GET /index" do
    let!(:admin_user) { create(:user, role: :admin) }
    let!(:school) { create(:school, owner: admin_user) }
    let!(:student) { create(:student) }

    it "returns a successful response" do
      get_with_auth(api_v1_students_path, admin_user)
      expect(response).to have_http_status(:success)
    end

    it "returns error if admin user does not own the school" do
      another_admin = create(:admin_user)
      get_with_auth(api_v1_students_path, another_admin)
      expect(response).to have_http_status(:not_found)
    end
  end
end
