# == Schema Information
#
# Table name: teaching_assignments
#
#  id                       :bigint           not null, primary key
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  available_day_id         :bigint           not null
#  student_class_subject_id :bigint           not null
#  user_id                  :bigint           not null
#
# Indexes
#
#  idx_assignments_user_subject_day_unique                 (user_id,student_class_subject_id,available_day_id) UNIQUE
#  index_teaching_assignments_on_available_day_id          (available_day_id)
#  index_teaching_assignments_on_scs_and_user              (student_class_subject_id,user_id) UNIQUE
#  index_teaching_assignments_on_student_class_subject_id  (student_class_subject_id)
#  index_teaching_assignments_on_user_id                   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (available_day_id => available_days.id)
#  fk_rails_...  (student_class_subject_id => student_class_subjects.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe Teaching::Assignment, type: :model do
  describe "associations" do
    let(:association) { described_class.reflect_on_association(target) }

    context "user association" do
      let(:target) { :user }
      it "belongs to user" do
        expect(association.macro).to eq :belongs_to
        expect(association.class_name).to eq "User"
      end
    end

    context "student_class_subject association" do
      let(:target) { :student_class_subject }
      it "belongs to student" do
        expect(association.macro).to eq :belongs_to
        expect(association.class_name).to eq "Subjects::StudentLink"
      end
    end
  end

  describe "validations" do
    let!(:user) { create(:user) }
    let!(:student_class_subject) { create(:student_class_subject) }
    let(:teaching_assignment) do
      build(
        :teaching_assignment,
        user: user,
        student_class_subject: student_class_subject
      )
    end
    it { expect(teaching_assignment).to be_valid }
    it do
      expect(teaching_assignment.student_class_subject_id).to eq(
        student_class_subject.id
      )
    end
    it { expect(teaching_assignment.user_id).to eq(user.id) }
  end
end
