# == Schema Information
#
# Table name: class_subjects
#
#  id         :bigint           not null, primary key
#  name       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe ClassSubject, type: :model do
  let(:class_subject) { build(:class_subject) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(class_subject).to be_valid
    end

    it 'is not valid without a name' do
      class_subject.name = nil
      expect(class_subject).not_to be_valid
    end

    it 'is not valid with a duplicate name' do
      create(:class_subject, name: 0)
      expect(class_subject).not_to be_valid
    end
  end
end
