# == Schema Information
#
# Table name: student_class_subjects
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  class_subject_id :bigint           not null
#  student_id       :bigint           not null
#
# Indexes
#
#  idx_on_student_id_class_subject_id_c0e296835a     (student_id,class_subject_id) UNIQUE
#  index_student_class_subjects_on_class_subject_id  (class_subject_id)
#  index_student_class_subjects_on_student_id        (student_id)
#
# Foreign Keys
#
#  fk_rails_...  (class_subject_id => class_subjects.id)
#  fk_rails_...  (student_id => students.id)
#
require "rails_helper"

RSpec.describe Subjects::StudentLink, type: :model do
  describe "associations" do
    let(:association) { described_class.reflect_on_association(target) }

    context "student association" do
      let(:target) { :student }
      it "belongs to student" do
        expect(association.macro).to eq :belongs_to
        expect(association.class_name).to eq "Student"
      end
    end

    context "class_subject association" do
      let(:target) { :class_subject }
      it "belongs to class_subject" do
        expect(association.macro).to eq :belongs_to
        expect(association.class_name).to eq "ClassSubject"
      end
    end

    context "teachig_assignments association" do
      let(:target) { :teaching_assignments }
      it "has many teaching_assignments" do
        expect(association.macro).to eq :has_many
        expect(association.class_name).to eq "Teaching::Assignment"
      end
    end

    context "lesson_notes association" do
      let(:target) { :lesson_notes }
      it "has many lesson_notes" do
        expect(association.macro).to eq :has_many
        expect(association.class_name).to eq "LessonNote"
      end
    end
  end
end
