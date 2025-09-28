# == Schema Information
#
# Table name: lesson_notes
#
#  id                       :bigint           not null, primary key
#  created_by_name          :string           default(""), not null
#  description              :text
#  expire_date              :date             not null
#  last_updated_by_name     :string
#  note_type                :integer          not null
#  title                    :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  created_by_id            :bigint
#  last_updated_by_id       :bigint
#  student_class_subject_id :bigint           not null
#
# Indexes
#
#  index_lesson_notes_on_created_by_id             (created_by_id)
#  index_lesson_notes_on_expire_date               (expire_date)
#  index_lesson_notes_on_last_updated_by_id        (last_updated_by_id)
#  index_lesson_notes_on_note_type                 (note_type)
#  index_lesson_notes_on_student_class_subject_id  (student_class_subject_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (last_updated_by_id => users.id) ON DELETE => nullify
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

    it "is not valid without a expire_date" do
      lesson_note.expire_date = nil
      expect(lesson_note).not_to be_valid
    end

    it "is not valid without a note_type" do
      lesson_note.note_type = nil
      expect(lesson_note).not_to be_valid
    end

    it "is not valid with invalid note_type enum value" do
      expect { lesson_note.note_type = 99 }.to raise_error(ArgumentError)
    end

    it "works expired? method" do
      # 期限が過ぎている場合 true
      lesson_note.expire_date = Date.current - 1.day
      expect(lesson_note.expired?).to be true
      # 期限当日ならfalse
      lesson_note.expire_date = Date.current
      expect(lesson_note.expired?).to be false
      # 期限前ならfalse
      lesson_note.expire_date = Date.current + 1.day
      expect(lesson_note.expired?).to be false
    end

    it "works snapshot_creator_name before_validation on create" do
      lesson_note.created_by_name = nil
      lesson_note.valid?
      expect(lesson_note.created_by_name).to eq lesson_note.created_by.name
    end

    it "is valid even if a last_updated_by_name is nil" do
      lesson_note.last_updated_by_name = nil
      expect(lesson_note).to be_valid
    end

    it "works snapshot_updater_name before_save" do
      updated_by = create(:user)
      lesson_note.last_updated_by = updated_by
      lesson_note.save!
      expect(lesson_note.last_updated_by_name).to eq updated_by.name
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

    context "created_by association" do
      let(:target) { :created_by }
      it "belongs to created_by" do
        expect(association.macro).to eq :belongs_to
        expect(association.class_name).to eq "User"
        expect(association.options).to include(
          inverse_of: :lesson_notes_created,
          optional: false
        )
      end
    end

    context "last_updated_by association" do
      let(:target) { :last_updated_by }
      it "belongs to last_updated_by" do
        expect(association.macro).to eq :belongs_to
        expect(association.class_name).to eq "User"
        expect(association.options).to include(
          inverse_of: :lesson_notes_updated,
          optional: true
        )
      end
    end
  end
end
