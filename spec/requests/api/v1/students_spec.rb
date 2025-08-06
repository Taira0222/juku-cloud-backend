require 'rails_helper'

RSpec.describe "Api::V1::Students", type: :request do
  describe "GET /index" do
    let!(:admin_user) { create(:admin_user) }
    let!(:school) { create(:school, owner: admin_user) }
    let!(:teacher) { create(:user, school: school) }
    let!(:teaching_assignment1) { create(:teaching_assignment, user: teacher, student: student1) }
    let!(:teaching_assignment2) { create(:teaching_assignment, user: teacher, student: student2) }
    let!(:student1) { create(:student, school: school) }
    let!(:student2) { create(:student, school: school) }

    it "returns a successful response" do
      get_with_auth(api_v1_students_path, admin_user)
      expect(response).to have_http_status(:success)
    end

    it "returns error if admin user does not own the school" do
      another_admin = create(:admin_user)
      get_with_auth(api_v1_students_path, another_admin)
      expect(response).to have_http_status(:not_found)
    end

    it "returns all studnents for the school" do
      get_with_auth(api_v1_students_path, admin_user)
      # JSON を ハッシュに変換
      json_response = JSON.parse(response.body)

      expect(json_response.size).to eq(2)
      expect(json_response.map { |s| s['id'] }).to include(student1.id, student2.id)
      expect(json_response.flat_map { |s| s['users'].map { |u| u['id'] } }).to include(teacher.id)
    end
  end
end
