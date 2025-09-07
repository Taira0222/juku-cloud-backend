require "rails_helper"

RSpec.describe Students::CreateService, type: :service do
  describe ".call" do
    subject(:call) { described_class.call(school:, create_params:) }

    let!(:school) { create(:school) }
    let!(:teacher1) { create(:user, :teacher) }
    let!(:teacher2) { create(:user, :teacher) }
    let!(:subject1) { create(:class_subject, :english) }
    let!(:subject2) { create(:class_subject, :japanese) }
    let!(:subject3) { create(:class_subject, :mathematics) }
    let!(:available_day1) { create(:available_day, :sunday) }
    let!(:available_day2) { create(:available_day, :monday) }
    let!(:available_day3) { create(:available_day, :tuesday) }

    context "with valid attributes" do
      let(:create_params) do
        {
          name: "Student Name",
          status: "active",
          school_stage: "junior_high_school",
          grade: 3,
          joined_on: Date.new(2023, 4, 1),
          desired_school: "Some High School",
          subject_ids: [ subject1.id, subject2.id ],
          available_day_ids: [ available_day1.id, available_day3.id ],
          assignments: [
            {
              teacher_id: teacher1.id,
              subject_id: subject1.id,
              day_id: available_day1.id
            },
            {
              teacher_id: teacher2.id,
              subject_id: subject2.id,
              day_id: available_day2.id
            }
          ]
        }
      end

      it "creates a new student and returns a successful result" do
        result = call
        expect(result).to be_ok
        expect(result.value).to be_a(Student)
        student = result.value
        expect(student.name).to eq("Student Name")
        expect(student.status).to eq("active")
        expect(student.school_stage).to eq("junior_high_school")
        expect(student.grade).to eq(3)
        expect(student.joined_on).to eq(Date.new(2023, 4, 1))
        expect(student.desired_school).to eq("Some High School")
        expect(student.school).to eq(school)
        expect(student.class_subject_ids).to match_array(
          [ subject1.id, subject2.id ]
        )
        expect(student.available_day_ids).to match_array(
          [ available_day1.id, available_day3.id ]
        )
        expect(student.teacher_ids).to match_array([ teacher1.id, teacher2.id ])
      end
    end

    context "with missing required attributes" do
      let(:create_params) do
        {
          name: "Student Name",
          status: "active",
          school_stage: "junior_high_school",
          grade: 3,
          joined_on: Date.new(2023, 4, 1),
          desired_school: "Some High School",
          subject_ids: [ subject1.id, subject2.id ],
          available_day_ids: [ available_day1.id, available_day3.id ],
          assignments: [
            {
              teacher_id: teacher1.id,
              subject_id: subject1.id,
              day_id: available_day1.id
            }
          ]
        }
      end

      it "returns a record invalid error result with validation messages" do
        create_params[:name] = nil
        result = call
        expect(result).not_to be_ok
        expect(result.errors).to eq(
          [ { code: "VALIDATION_FAILED", field: :name, message: "名前 を入力してください" } ]
        )
      end

      it "returns an argument error when subject_ids are empty" do
        create_params[:subject_ids] = []
        result = call
        expect(result).not_to be_ok
        expect(result.errors).to eq(
          [
            {
              code: "VALIDATION_FAILED",
              message:
                I18n.t("students.errors.create_service.subject_ids_empty")
            }
          ]
        )
      end

      it "returns an argument error when available_day_ids are empty" do
        create_params[:available_day_ids] = []
        result = call
        expect(result).not_to be_ok
        expect(result.errors).to eq(
          [
            {
              code: "VALIDATION_FAILED",
              message:
                I18n.t("students.errors.create_service.available_day_ids_empty")
            }
          ]
        )
      end

      it "returns an argument error when assignments are empty" do
        create_params[:assignments] = []
        result = call
        expect(result).not_to be_ok
        expect(result.errors).to eq(
          [
            {
              code: "VALIDATION_FAILED",
              message:
                I18n.t("students.errors.create_service.assignments_empty")
            }
          ]
        )
      end

      it "returns a record not found error when a teacher does not exist" do
        create_params[:assignments] = [
          { teacher_id: 999, subject_id: 1, day_id: 1 }
        ]
        result = call
        expect(result).not_to be_ok
        expect(result.errors).to eq(
          [
            {
              code: "VALIDATION_FAILED",
              message:
                I18n.t("students.errors.create_service.unknown_validation")
            }
          ]
        )
      end
    end
  end
end
