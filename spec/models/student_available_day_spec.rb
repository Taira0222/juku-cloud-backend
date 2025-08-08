# == Schema Information
#
# Table name: student_available_days
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  available_day_id :bigint           not null
#  student_id       :bigint           not null
#
# Indexes
#
#  idx_on_student_id_available_day_id_b42ed887dc     (student_id,available_day_id) UNIQUE
#  index_student_available_days_on_available_day_id  (available_day_id)
#  index_student_available_days_on_student_id        (student_id)
#
# Foreign Keys
#
#  fk_rails_...  (available_day_id => available_days.id)
#  fk_rails_...  (student_id => students.id)
#
require 'rails_helper'

RSpec.describe StudentAvailableDay, type: :model do
    describe 'associations' do
    let(:association) do
      described_class.reflect_on_association(target)
    end

    context 'student associations' do
      let(:target) { :student }
      it 'belongs to student' do
        expect(association.macro).to eq(:belongs_to)
        expect(association.name).to eq(:student)
      end
    end

    context 'available_day associations' do
      let(:target) { :available_day }
      it 'belongs to available_day' do
        expect(association.macro).to eq(:belongs_to)
        expect(association.name).to eq(:available_day)
      end
    end
  end
end
