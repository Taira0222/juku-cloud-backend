require "rails_helper"

RSpec.describe Students::RelationSetter, type: :service do
  describe ".call" do
    subject(:call) do
      described_class.call(
        student: student,
        subject_ids: subject_ids,
        available_day_ids: available_day_ids,
        assignments: assignments
      )
    end

    let!(:student) { create(:student) }
    let!(:subject1) { create(:class_subject, :english) }
    let!(:subject2) { create(:class_subject, :japanese) }
    let!(:available_day1) { create(:available_day, :sunday) }
    let!(:available_day2) { create(:available_day, :monday) }
    let!(:teacher1) { create(:user, :teacher) }
    let!(:teacher2) { create(:user, :teacher) }

    context "with valid attributes" do
      let(:subject_ids) { [ subject1.id, subject2.id ] }
      let(:available_day_ids) { [ available_day1.id, available_day2.id ] }
      let(:assignments) do
        [
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
      end

      it "sets relations correctly" do
        call
        student.reload
        expect(student).to have_attributes(
          class_subject_ids: match_array([ subject1.id, subject2.id ]),
          available_day_ids:
            match_array([ available_day1.id, available_day2.id ]),
          teacher_ids: match_array([ teacher1.id, teacher2.id ])
        )
      end
    end

    context "subject_ids" do
      let(:available_day_ids) { [ available_day1.id ] }
      let(:assignments) do
        [
          {
            teacher_id: teacher1.id,
            subject_id: subject1.id,
            day_id: available_day1.id
          }
        ]
      end

      context "when subject_ids has duplicates" do
        let(:subject_ids) { [ subject1.id, subject1.id, subject2.id ] }

        it "does not raise an error even if subject_ids includes duplicates" do
          expect { call }.not_to raise_error
        end
      end

      context "when subject_ids is empty" do
        let(:subject_ids) { [] }

        it "raises an ArgumentError when subject_ids is empty" do
          expect { call }.to raise_error(
            ArgumentError,
            I18n.t("students.errors.subject_ids_empty")
          )
        end
      end

      context "when subject_ids contains non-existing IDs" do
        let(:subject_ids) { [ subject1.id, 9999 ] }

        it "raises a RecordNotFound when subject_ids contains non-existing IDs" do
          expect { call }.to raise_error(
            ActiveRecord::RecordNotFound,
            I18n.t("students.errors.missing_subject_ids")
          )
        end
      end
    end

    context "available_day_ids" do
      let(:subject_ids) { [ subject1.id ] }
      let(:assignments) do
        [
          {
            teacher_id: teacher1.id,
            subject_id: subject1.id,
            day_id: available_day1.id
          }
        ]
      end

      context "when available_day_ids has duplicates" do
        let(:available_day_ids) { [ available_day1.id, available_day1.id ] }

        it "does not raise an error even if available_day_ids includes duplicates" do
          expect { call }.not_to raise_error
        end
      end

      context "when available_day_ids is empty" do
        let(:available_day_ids) { [] }

        it "raises an ArgumentError when available_day_ids is empty" do
          expect { call }.to raise_error(
            ArgumentError,
            I18n.t("students.errors.available_day_ids_empty")
          )
        end
      end

      context "when available_day_ids contains non-existing IDs" do
        let(:available_day_ids) { [ available_day1.id, 9999 ] }

        it "raises a RecordNotFound when available_day_ids contains non-existing IDs" do
          expect { call }.to raise_error(
            ActiveRecord::RecordNotFound,
            I18n.t("students.errors.missing_available_day_ids")
          )
        end
      end
    end

    context "assignments" do
      let(:subject_ids) { [ subject1.id ] }
      let(:available_day_ids) { [ available_day1.id ] }

      context "when assignments is empty" do
        let(:assignments) { [] }

        it "raises an ArgumentError when assignments is empty" do
          expect { call }.to raise_error(
            ArgumentError,
            I18n.t("students.errors.assignments_empty")
          )
        end
      end

      context "when subject_id does not exist" do
        let(:assignments) do
          [
            {
              teacher_id: teacher1.id,
              subject_id: 9999,
              day_id: available_day1.id
            }
          ]
        end

        it "raises an ArgumentError" do
          expect { call }.to raise_error(
            ArgumentError,
            I18n.t("students.errors.assignment.subject_not_linked")
          )
        end
      end

      context "when teacher_id does not exist" do
        let(:assignments) do
          [
            {
              teacher_id: 9999,
              subject_id: subject1.id,
              day_id: available_day1.id
            }
          ]
        end
        it "raises an ActiveRecord::RecordNotFound" do
          expect { call }.to raise_error(
            ActiveRecord::RecordNotFound,
            I18n.t("students.errors.assignment.missing_teacher")
          )
        end
      end

      context "when day_id does not exist" do
        let(:assignments) do
          [ { teacher_id: teacher1.id, subject_id: subject1.id, day_id: 9999 } ]
        end

        it "raises an ActiveRecord::RecordNotFound" do
          expect { call }.to raise_error(
            ActiveRecord::RecordNotFound,
            I18n.t("students.errors.assignment.missing_day")
          )
        end
      end
    end
  end
end
