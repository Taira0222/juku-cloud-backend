require "rails_helper"

RSpec.describe Students::IndexQuery, type: :query do
  describe ".call" do
    let!(:user) { create(:user, role: :admin) }
    let!(:school) { create(:school, owner: user) }
    let!(:students) { create_list(:student, 5, school: school) }
    let(:index_params) do
      {
        searchKeyword: "Test",
        school_stage: "junior_high_school",
        grade: 1,
        page: 1,
        perPage: 10
      }
    end
    subject(:call) do
      described_class.call(school: school, index_params: index_params)
    end

    it "returns the current user and students" do
      result = call
      expect(result).to match_array(school.students)
    end

    it "does not return students with a different search keyword" do
      index_params[:searchKeyword] = "Another"
      result = call
      expect(result).not_to match_array(school.students)
    end

    # 小文字と大文字の区別はつけないことを確認
    it "returns students even with a different search keyword" do
      index_params[:searchKeyword] = "test"
      result = call
      expect(result).to match_array(school.students)
    end

    it "does not return students with a different school stage" do
      index_params[:school_stage] = "high_school"
      result = call
      expect(result).not_to match_array(school.students)
    end

    it "does not return students with a different grade" do
      index_params[:grade] = 2
      result = call
      expect(result).not_to match_array(school.students)
    end

    it "does not return students with a different page" do
      index_params[:page] = 10
      result = call
      expect(result).not_to match_array(school.students)
    end

    it "returns students even if a different perPage" do
      index_params[:perPage] = 10
      result = call
      expect(result).to match_array(school.students)
    end

    it "does not return students from other schools" do
      other_school = create(:school)
      create_list(:student, 3, school: other_school)
      result = call
      expect(result).not_to include(*other_school.students)
    end
  end
end
