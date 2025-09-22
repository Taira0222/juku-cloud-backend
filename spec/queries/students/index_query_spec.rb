require "rails_helper"

RSpec.describe Students::IndexQuery, type: :query do
  describe ".call" do
    let!(:user) { create(:user, role: :admin) }
    let!(:school) { create(:school, owner: user) }
    let!(:another_user) { create(:another_user, school: school) }
    let!(:students) { create_list(:student, 5, school: school) }
    let!(:another_students) { create_list(:another_student, 5, school: school) }
    let(:index_params) do
      {
        searchKeyword: "Student",
        school_stage: "junior_high_school",
        grade: 1,
        page: 1,
        perPage: 10
      }
    end

    context "admin user" do
      subject(:call) do
        described_class.call(
          school: school,
          index_params: index_params,
          current_user: user
        )
      end
      it "returns school students" do
        result = call
        expect(result).to match_array(school.students)
        expect(result.count).to eq(10) # another_studentsも含む
      end

      it "does not return students with a different search keyword" do
        index_params[:searchKeyword] = "hoge"
        result = call
        expect(result).not_to match_array(school.students)
      end

      # 小文字と大文字の区別はつけないことを確認
      it "returns students even with a different search keyword" do
        index_params[:searchKeyword] = "student"
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

    context "teacher user" do
      subject(:call) do
        described_class.call(
          school: school,
          index_params: index_params,
          current_user: another_user
        )
      end

      # 担当割り当てを用意
      before do
        class_subject = create(:class_subject)
        available_day = create(:available_day)

        another_students.each do |student|
          scs =
            create(
              :student_class_subject,
              student: student,
              class_subject: class_subject
            )
          create(
            :teaching_assignment,
            user: another_user,
            student_class_subject: scs,
            available_day: available_day
          )
        end
      end

      it "returns only students assigned to the teacher" do
        result = call
        expect(result).to match_array(another_students)
        expect(result.count).to eq(5)
      end

      it "does not return students from other schools" do
        other_school = create(:school)
        other_students = create_list(:student, 3, school: other_school)
        result = call
        expect(result).not_to include(*other_students)
      end
    end
  end
end
