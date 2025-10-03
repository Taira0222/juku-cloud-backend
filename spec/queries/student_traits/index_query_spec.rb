require "rails_helper"

RSpec.describe StudentTraits::IndexQuery, type: :query do
  describe ".call" do
    let!(:school) { create(:school) }
    let!(:student) { create(:student, school: school) }
    let!(:student_trait1) do
      create(:student_trait, title: "kind trait", student: student)
    end
    let!(:student_trait2) do
      create(:student_trait, title: "helpful trait", student: student)
    end
    let!(:student_traits) do
      create_list(:student_trait, 20, title: "extra", student: student)
    end
    subject(:call) do
      described_class.call(school: school, index_params: index_params)
    end

    context "valid params" do
      let(:index_params) { { studentId: student.id, page: 1, perPage: 10 } }

      it "returns student traits with pagination" do
        result = call
        expect(result.size).to eq(10) # ページネーションの確認
        expect(result).to include(student_trait1, student_trait2)
      end

      it "returns student traits with search keyword" do
        index_params[:searchKeyword] = "kind"
        result = call
        expect(result.size).to eq(1)
        expect(result.first).to eq(student_trait1)
      end

      it "returns student traits with partial match" do
        index_params[:searchKeyword] = "trait"
        result = call
        expect(result.size).to eq(2)
        expect(result).to include(student_trait1, student_trait2)
      end

      it "returns student traits sorted by created_at desc" do
        index_params[:sortBy] = "created_at_desc"
        result = call
        expect(result.first.created_at).to be >= result.second.created_at
      end

      it "returns student traits sorted by created_at asc" do
        index_params[:sortBy] = "created_at_asc"
        result = call
        expect(result.first.created_at).to be <= result.second.created_at
      end

      it "returns student traits sorted by updated_at desc" do
        student_trait1.update!(title: "updated title")
        index_params[:sortBy] = "updated_at_desc"
        result = call
        expect(result.first.updated_at).to be >= result.second.updated_at
      end

      it "returns student traits sorted by updated_at asc" do
        student_trait1.update!(title: "updated title")
        index_params[:sortBy] = "updated_at_asc"
        result = call
        expect(result.first.updated_at).to be <= result.second.updated_at
      end

      it "falls back to default sorting when sortBy is invalid" do
        index_params[:sortBy] = "invalid_option"
        result = call
        expect(result).to include(student_trait1, student_trait2)
      end

      it "returns second page of student traits" do
        index_params[:page] = 2
        index_params[:perPage] = 10
        result = call
        expect(result.size).to eq(10)
        expect(result).not_to include(student_trait1, student_trait2)
      end
    end

    context "invalid params" do
      let(:index_params) { { studentId: 0, page: 1, perPage: 10 } }

      it "raises ActiveRecord::RecordNotFound when studentId is nil" do
        expect { call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
