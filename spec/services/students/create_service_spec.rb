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
              day_id: available_day3.id
            }
          ]
        }
      end

      it "creates a new student and returns a successful result" do
        result = call
        expect(result).to have_attributes(
          name: "Student Name",
          status: "active",
          school_stage: "junior_high_school",
          grade: 3,
          joined_on: Date.new(2023, 4, 1),
          desired_school: "Some High School",
          school: school,
          class_subject_ids: match_array([ subject1.id, subject2.id ]),
          available_day_ids:
            match_array([ available_day1.id, available_day3.id ]),
          teacher_ids: match_array([ teacher1.id, teacher2.id ])
        )
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
        expect { call }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "returns an argument error when subject_ids are empty" do
        create_params[:subject_ids] = []
        expect { call }.to raise_error(
          ArgumentError,
          I18n.t("students.errors.subject_ids_empty")
        )
      end

      it "returns an argument error when available_day_ids are empty" do
        create_params[:available_day_ids] = []
        expect { call }.to raise_error(
          ArgumentError,
          I18n.t("students.errors.available_day_ids_empty")
        )
      end

      it "returns an argument error when assignments are empty" do
        create_params[:assignments] = []
        expect { call }.to raise_error(
          ArgumentError,
          I18n.t("students.errors.assignments_empty")
        )
      end

      it "returns a record not found error when a teacher does not exist" do
        create_params[:assignments] = [
          {
            teacher_id: 999,
            subject_id: subject1.id,
            day_id: available_day1.id
          }
        ]
        expect { call }.to raise_error(
          ActiveRecord::RecordNotFound,
          I18n.t("students.errors.assignment.missing_teacher")
        )
      end
    end
  end
end
