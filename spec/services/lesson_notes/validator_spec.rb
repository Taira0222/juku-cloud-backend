require "rails_helper"

RSpec.describe LessonNotes::Validator do
  describe ".call" do
    let!(:school) { create(:school) }
    let!(:student) { create(:student, school: school) }
    let!(:class_subject) { create(:class_subject) }
    let!(:student_class_subject) do
      create(
        :student_class_subject,
        student: student,
        class_subject: class_subject
      )
    end
    subject(:call) { described_class.call(school: school, params: params) }

    context "when params are valid" do
      let(:params) do
        {
          student_id: student.id,
          subject_id: class_subject.id,
          title: "Test Title",
          description: "Test Description",
          note_type: "homework",
          expire_date: Date.today + 7.days
        }
      end

      it "returns the student_class_subject" do
        result = call
        expect(result).to eq(student_class_subject)
      end
    end

    context "when params are nil" do
      let(:params) { nil }
      it "raises an ArgumentError" do
        expect { call }.to raise_error(
          ArgumentError,
          I18n.t("lesson_notes.errors.params_must_not_be_nil")
        )
      end
    end

    context "when student_class_subject is not found" do
      let(:params) do
        {
          student_id: 0, # Invalid student_id
          subject_id: class_subject.id,
          title: "Test Title",
          description: "Test Description",
          note_type: "info",
          expire_date: Date.today + 7.days
        }
      end

      it "raises an ArgumentError" do
        expect { call }.to raise_error(
          ArgumentError,
          I18n.t("lesson_notes.errors.student_class_subject_not_found")
        )
      end
    end
  end
end
