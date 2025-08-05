require 'rails_helper'

RSpec.describe "Api::V1::Teachers", type: :request do
  describe "GET /index" do
    let!(:admin_user) { create(:admin_user) }
    let!(:another_admin) { create(:admin_user) }
    let!(:school) { create(:school, owner: admin_user) }
    let!(:teacher1) { create(:user, school: school) }
    let!(:teacher2) { create(:user, school: school) }

    context "signed in user" do
      it "returns a successful response" do
        get_with_auth(api_v1_teachers_path, admin_user)
        expect(response).to have_http_status(:success)
      end
      it 'returns error if admin user does not own the school' do
        get_with_auth(api_v1_teachers_path, another_admin)
        expect(response).to have_http_status(:not_found)
      end

      it "returns all teachers for the school" do
        get_with_auth(api_v1_teachers_path, admin_user)
        # JSON を ハッシュに変換
        json_response = JSON.parse(response.body)
        expect(json_response['teachers'].size).to eq(2)
        expect(json_response['teachers'].map { |t| t['id'] }).to include(teacher1.id, teacher2.id)
      end

      it "does not return teachers from other schools" do
        other_school = create(:school)
        other_teacher = create(:user, school: other_school)

        get_with_auth(api_v1_teachers_path, admin_user)
        json_response = JSON.parse(response.body)
        expect(json_response['teachers'].map { |t| t['id'] }).not_to include(other_teacher.id)
      end
    end

    context "unauthenticated user" do
      it "returns an unauthorized response" do
        get api_v1_teachers_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
