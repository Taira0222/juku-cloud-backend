require "rails_helper"

RSpec.describe "User Token Validation", type: :request do
  describe "GET api/v1/auth/validate_token" do
    context "admin user" do
      let(:admin_user) { create(:admin_user) }
      let!(:admin_school) { create(:school, owner: admin_user) }
      before { get_with_auth(api_v1_auth_validate_token_path, admin_user) }
      it "returns a success response" do
        expect(response).to have_http_status(:success)
      end

      it "returns the admin user information" do
        expect(json[:data]).to include(
          id: admin_user.id,
          name: admin_user.name,
          email: admin_user.email,
          role: admin_user.role,
          school: admin_school.as_json(only: %i[id name]).symbolize_keys
        )
      end
      it "does not return without auth" do
        get api_v1_auth_validate_token_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "teacher user" do
      let(:teacher_user) { create(:user) }

      before { get_with_auth(api_v1_auth_validate_token_path, teacher_user) }

      it "returns a success response" do
        expect(response).to have_http_status(:success)
      end

      it "returns the teacher user information" do
        expect(json[:data]).to include(
          id: teacher_user.id,
          name: teacher_user.name,
          email: teacher_user.email,
          role: teacher_user.role,
          school: teacher_user.school.as_json(only: %i[id name]).symbolize_keys
        )
      end
    end
  end
end
