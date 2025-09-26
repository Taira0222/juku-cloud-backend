# == Schema Information
#
# Table name: lesson_notes
#
#  id                       :bigint           not null, primary key
#  description              :text
#  title                    :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  student_class_subject_id :bigint           not null
#
# Indexes
#
#  index_lesson_notes_on_student_class_subject_id  (student_class_subject_id)
#
# Foreign Keys
#
#  fk_rails_...  (student_class_subject_id => student_class_subjects.id)
#
require "rails_helper"

RSpec.describe LessonNote, type: :model do
  describe "validation" do
    let(:lesson_note) { build(:lesson_note) }

    it "is valid with valid attributes" do
      expect(lesson_note).to be_valid
    end

    it "is not valid without a title" do
      lesson_note.title = nil
      expect(lesson_note).not_to be_valid
    end

    it "is valid with 50 characters title" do
      lesson_note.title = "a" * 50
      expect(lesson_note).to be_valid
    end

    it "is not valid with 51 characters title" do
      lesson_note.title = "a" * 51
      expect(lesson_note).not_to be_valid
    end

    it "is valid even if a description is nil" do
      lesson_note.description = nil
      expect(lesson_note).to be_valid
    end

    it "is valid with 1000 characters description" do
      lesson_note.description = "a" * 1000
      expect(lesson_note).to be_valid
    end

    it "is not valid with 1001 characters description" do
      lesson_note.description = "a" * 1001
      expect(lesson_note).not_to be_valid
    end
  end

  describe "associations" do
    let(:association) { described_class.reflect_on_association(target) }
    context "student_class_subject association" do
      let(:target) { :student_class_subject }
      it "belongs to student_class_subject" do
        expect(association.macro).to eq :belongs_to
        expect(association.class_name).to eq "Subjects::StudentLink"
      end
    end
  end
end
