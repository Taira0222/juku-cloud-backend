# == Schema Information
#
# Table name: teaching_assignments
#
#  id              :bigint           not null, primary key
#  started_on      :date
#  teaching_status :boolean
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  student_id      :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_teaching_assignments_on_student_id  (student_id)
#  index_teaching_assignments_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (student_id => students.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe TeachingAssignment, type: :model do
  describe 'associations' do
    let(:association) do
      described_class.reflect_on_association(target)
    end

    context 'user association' do
      let(:target) { :user }
      it "belongs to user" do
        expect(association.macro).to eq :belongs_to
        expect(association.class_name).to eq 'User'
      end
    end

    context 'student association' do
      let(:target) { :student }
      it "belongs to student" do
        expect(association.macro).to eq :belongs_to
        expect(association.class_name).to eq 'Student'
      end
    end
  end

  describe 'validations' do
    let!(:user) { create(:user) }
    let!(:student) { create(:student) }
    let(:teaching_assignment) { build(:teaching_assignment, user: user, student: student) }
    it { expect(teaching_assignment).to be_valid }
    it { expect(teaching_assignment.student_id).to eq(student.id) }
    it { expect(teaching_assignment.user_id).to eq(user.id) }
    it { expect(teaching_assignment.started_on).to be_present }
  end
end
