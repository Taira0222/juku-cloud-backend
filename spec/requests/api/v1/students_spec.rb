require "rails_helper"

RSpec.describe "Api::V1::Students", type: :request do
  describe "GET /index" do
    let!(:admin_user) { create(:user, role: :admin) }
    let!(:school) { create(:school, owner: admin_user) }
    let!(:students) { create_list(:student, 5, school: school) }
    let(:index_params) do
      {
        searchKeyword: nil,
        school_stage: nil,
        grade: nil,
        page: 1,
        perPage: 10
      }
    end

    it "returns a successful response" do
      get_with_auth(api_v1_students_path, admin_user, params: index_params)
      expect(response).to have_http_status(:success)
      # symbolize_names: trueを使ってキーをシンボル化
      json_response = JSON.parse(response.body, symbolize_names: true)

      # 形を確認
      expect(json_response).to include(:students, :meta)
      expect(json_response[:students]).to be_an(Array)
      expect(json_response[:students].size).to eq(5)
      first = json_response[:students].first

      # students の中身を確認
      expect(first.keys).to match_array(
        %i[
          id
          name
          status
          school_stage
          grade
          joined_on
          desired_school
          class_subjects
          available_days
          teachers
        ]
      )
      expect(first[:class_subjects]).to all(include(:id, :name))
      expect(first[:available_days]).to all(include(:id, :name))
      expect(first[:teachers]).to all(include(:id, :name, :role))

      # meta の中身を確認
      expect(json_response[:meta]).to include(
        :total_pages,
        :total_count,
        :current_page,
        :per_page
      )
      expect(json_response[:meta][:total_pages]).to eq(1)
      expect(json_response[:meta][:total_count]).to eq(5)
      expect(json_response[:meta][:current_page]).to eq(1)
      expect(json_response[:meta][:per_page]).to eq(10)
    end

    it "will return empty array when no students match the search criteria" do
      get_with_auth(
        api_v1_students_path,
        admin_user,
        params: index_params.merge(searchKeyword: "NonExistentName")
      )
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body, symbolize_names: true)

      expect(json_response[:students]).to be_an(Array)
      expect(json_response[:students].size).to eq(0)
      expect(json_response[:meta][:total_count]).to eq(0)
    end
  end
end
