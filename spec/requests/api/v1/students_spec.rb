require "rails_helper"

RSpec.describe "Api::V1::Students", type: :request do
  describe "GET /index" do
    let!(:admin_user) { create(:user, role: :admin) }
    let!(:school) { create(:school, owner: admin_user) }
    let!(:students) { create_list(:student, 5, school: school) }

    it "returns a successful response" do
      get_with_auth(api_v1_students_path, admin_user)
      expect(response).to have_http_status(:success)
      # symbolize_names: trueを使ってキーをシンボル化
      json_response = JSON.parse(response.body, symbolize_names: true)
      expect(json_response[:students]).to be_an(Array)
      expect(json_response[:students].size).to eq(5)
    end
  end
end
