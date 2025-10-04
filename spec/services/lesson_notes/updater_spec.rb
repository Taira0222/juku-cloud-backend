require "rails_helper"

RSpec.describe LessonNotes::Updater do
  describe ".call" do
    let!(:school) { create(:school) }
    let!(:admin_user) { create(:admin_user) }
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
    let!(:lesson_note) do
      create(
        :lesson_note,
        student_class_subject: student_class_subject,
        created_by: admin_user,
        created_by_name: admin_user.name
      )
    end

    subject(:call) do
      described_class.call(
        student_class_subject:,
        current_user:,
        update_params:
      )
    end

    context "with valid parameters" do
      let(:update_params) do
        {
          id: lesson_note.id,
          title: "Test Lesson Note",
          description: "This is a test lesson note.",
          note_type: "homework",
          expire_date: Date.current + 7.days
        }
      end

      it "updates the lesson note" do
        result = call

        expect(result).to be_persisted
        expect(result.id).to eq(lesson_note.id)
        expect(result.title).to eq("Test Lesson Note")
        expect(result.description).to eq("This is a test lesson note.")
        expect(result.note_type).to eq("homework")
        expect(result.expire_date).to eq(Date.current + 7.days)
        expect(result.student_class_subject).to eq(student_class_subject)
        expect(result.last_updated_by).to eq(current_user)
        expect(result.last_updated_by_name).to eq(current_user.name)
      end
    end

    context "with invalid parameters" do
      context "when id does not exist" do
        let(:update_params) do
          {
            id: 9999,
            title: "Test Lesson Note",
            description: "This is a test lesson note.",
            note_type: "homework",
            expire_date: Date.current + 7.days
          }
        end

        it "raises an error" do
          expect { call }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when expire_date changes to a past date" do
        let(:update_params) do
          {
            id: lesson_note.id,
            title: "Test Lesson Note",
            description: "This is a test lesson note.",
            note_type: "homework",
            expire_date: Date.current - 1.day
          }
        end

        it "does not update the lesson note" do
          expect { call }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "when title is missing" do
        let(:update_params) do
          {
            id: lesson_note.id,
            description: "This is a test lesson note.",
            note_type: "homework",
            expire_date: Date.current + 7.days
          }
        end

        it "does not update the lesson note" do
          expect { call }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "when note_type is invalid" do
        let(:update_params) do
          {
            id: lesson_note.id,
            title: "Test Lesson Note",
            description: "This is a test lesson note.",
            note_type: "invalid_type",
            expire_date: Date.current + 7.days
          }
        end

        it "does not update the lesson note" do
          expect { call }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
