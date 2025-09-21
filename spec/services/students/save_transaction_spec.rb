require "rails_helper"

RSpec.describe Students::SaveTransaction, type: :service do
  describe ".run!" do
    let!(:student) { create(:student) }
    let!(:subject1) { create(:class_subject, :english) }
    let!(:subject2) { create(:class_subject, :japanese) }
    let!(:available_day1) { create(:available_day, :sunday) }
    let!(:available_day2) { create(:available_day, :monday) }
    let!(:teacher1) { create(:user, :teacher) }
    let!(:teacher2) { create(:user, :teacher) }
    let!(:school) { create(:school) }

    context "with valid attributes" do
      let(:params) do
        {
          subject_ids: [ subject1.id, subject2.id ],
          available_day_ids: [ available_day1.id, available_day2.id ],
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
      context "when creating a student" do
        it "creates a student with relations" do
          student =
            described_class.run!(params) do
              Student.create!(
                name: "Test Student",
                status: "active",
                school_stage: "junior_high_school",
                grade: 3,
                joined_on: Date.yesterday,
                desired_school: "Test School",
                school: school
              )
            end
          expect(student).to have_attributes(
            name: "Test Student",
            status: "active",
            school_stage: "junior_high_school",
            grade: 3,
            joined_on: Date.yesterday,
            desired_school: "Test School",
            school: school,
            class_subject_ids: match_array([ subject1.id, subject2.id ]),
            available_day_ids:
              match_array([ available_day1.id, available_day2.id ]),
            teacher_ids: match_array([ teacher1.id, teacher2.id ])
          )
        end
      end

      context "when updating a student" do
        it "updates the student with new attributes" do
          updated_student =
            described_class.run!(params) do
              student.update!(
                name: "Updated Name",
                status: "active",
                school_stage: "junior_high_school",
                grade: 3,
                joined_on: Date.yesterday,
                desired_school: "Test School",
                school: school
              )
              student
            end

          expect(updated_student).to have_attributes(
            name: "Updated Name",
            status: "active",
            school_stage: "junior_high_school",
            grade: 3,
            joined_on: Date.yesterday,
            desired_school: "Test School",
            school: school,
            class_subject_ids: match_array([ subject1.id, subject2.id ]),
            available_day_ids:
              match_array([ available_day1.id, available_day2.id ]),
            teacher_ids: match_array([ teacher1.id, teacher2.id ])
          )
        end
      end
    end
  end
end
