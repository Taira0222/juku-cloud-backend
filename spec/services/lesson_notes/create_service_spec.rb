require "rails_helper"

RSpec.describe LessonNotes::CreateService do
  describe ".call" do
    let!(:school) { create(:school) }
    let!(:current_user) { create(:user, school: school) }
    let!(:student) { create(:student, school: school) }
    let!(:class_subject) { create(:class_subject) }
    let!(:student_class_subject) do
      create(
        :student_class_subject,
        student: student,
        class_subject: class_subject
      )
    end

    subject(:call) do
      described_class.call(
        student_class_subject:,
        current_user:,
        create_params:
      )
    end

    context "with valid parameters" do
      let(:create_params) do
        {
          title: "Test Lesson Note",
          description: "This is a test lesson note.",
          note_type: "homework",
          expire_date: Date.today + 7.days
        }
      end

      it "creates a new lesson note" do
        lesson_note = call

        expect(lesson_note).to be_persisted
        expect(lesson_note.title).to eq("Test Lesson Note")
        expect(lesson_note.description).to eq("This is a test lesson note.")
        expect(lesson_note.note_type).to eq("homework")
        expect(lesson_note.expire_date).to eq(Date.today + 7.days)
        expect(lesson_note.student_class_subject).to eq(student_class_subject)
        expect(lesson_note.created_by).to eq(current_user)
        expect(lesson_note.created_by_name).to eq(current_user.name)
      end
    end

    context "with invalid parameters" do
      context "when title is missing" do
        let(:create_params) do
          {
            description: "This is a test lesson note.",
            note_type: "homework",
            expire_date: Date.today + 7.days
          }
        end

        it "does not create a lesson note" do
          expect { call }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "when note_type is invalid" do
        let(:create_params) do
          {
            title: "Test Lesson Note",
            description: "This is a test lesson note.",
            note_type: "invalid_type",
            expire_date: Date.today + 7.days
          }
        end

        it "does not create a lesson note" do
          expect { call }.to raise_error(ArgumentError)
        end
      end

      context "when expire_date is in the past" do
        let(:create_params) do
          {
            title: "Test Lesson Note",
            description: "This is a test lesson note.",
            note_type: "homework",
            expire_date: Date.today - 1.day
          }
        end

        it "does not create a lesson note" do
          expect { call }.to raise_error(
            ArgumentError,
            I18n.t("lesson_notes.errors.expire_date_must_not_be_in_the_past")
          )
        end
      end
    end
  end
end
