# == Schema Information
#
# Table name: available_days
#
#  id         :bigint           not null, primary key
#  name       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe AvailableDay, type: :model do
  let(:available_day) { build(:available_day) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(available_day).to be_valid
    end

    it 'is not valid without a name' do
      available_day.name = nil
      expect(available_day).not_to be_valid
    end

    it 'is not valid with a duplicate name' do
      create(:available_day, name: 0)
      expect(available_day).not_to be_valid
    end
  end
end
