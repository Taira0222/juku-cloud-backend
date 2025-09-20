require "rails_helper"

RSpec.describe Students::Updater, type: :service do
  describe ".call" do
    subject(:call) { described_class.call(school:, update_params:) }

    let!(:school) { create(:school) }
    let!(:student) { create(:student, school: school) }
    let!(:teacher1) { create(:user, :teacher) }
    let!(:teacher2) { create(:user, :teacher) }
    let!(:subject1) { create(:class_subject, :english) }
    let!(:subject2) { create(:class_subject, :japanese) }
    let!(:available_day1) { create(:available_day, :sunday) }
    let!(:available_day2) { create(:available_day, :monday) }

    context "with valid attributes" do
      let(:update_params) do
        {
          id: student.id,
          name: "Student Name",
          status: "active",
          school_stage: "junior_high_school",
          grade: 3,
          joined_on: Date.new(2023, 4, 1),
          desired_school: "Some High School",
          subject_ids: [subject1.id, subject2.id],
          available_day_ids: [available_day1.id, available_day2.id],
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

      it "updates the student and returns a successful result" do
        result = call
        expect(result).to have_attributes(
          id: student.id,
          name: "Student Name",
          status: "active",
          school_stage: "junior_high_school",
          grade: 3,
          joined_on: Date.new(2023, 4, 1),
          desired_school: "Some High School",
          school: school,
          class_subject_ids: match_array([subject1.id, subject2.id]),
          available_day_ids:
            match_array([available_day1.id, available_day2.id]),
          teacher_ids: match_array([teacher1.id, teacher2.id])
        )
      end
    end

    context "with missing required attributes" do
      context "when student does not exist" do
        let(:update_params) do
          {
            id: 9999, # 存在しないID
            name: "Student Name",
            status: "active",
            school_stage: "junior_high_school",
            grade: 3,
            joined_on: Date.new(2023, 4, 1),
            desired_school: "Some High School",
            subject_ids: [subject1.id, subject2.id],
            available_day_ids: [available_day1.id, available_day2.id],
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
        it "raises a RecordNotFound error" do
          expect { call }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when params is nil" do
        let(:update_params) { nil }
        it "returns a record invalid error result with validation messages" do
          expect { call }.to raise_error(
            ArgumentError,
            I18n.t("students.errors.params_must_not_be_nil")
          )
        end
      end

      context "when update! fails due to validation errors" do
        let(:update_params) do
          {
            id: student.id,
            name: "", # 名前が空でバリデーションエラーになる
            status: "active",
            school_stage: "junior_high_school",
            grade: 3,
            joined_on: Date.new(2023, 4, 1),
            desired_school: "Some High School"
          }
        end

        it "raises a RecordInvalid error" do
          expect { call }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end
end
