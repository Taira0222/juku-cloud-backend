# == Schema Information
#
# Table name: user_available_days
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  available_day_id :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_user_available_days_on_available_day_id              (available_day_id)
#  index_user_available_days_on_user_id                       (user_id)
#  index_user_available_days_on_user_id_and_available_day_id  (user_id,available_day_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (available_day_id => available_days.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Availability::UserLink, type: :model do
  describe 'associations' do
    let(:association) do
      described_class.reflect_on_association(target)
    end

    context 'user associations' do
      let(:target) { :user }
      it 'belongs to user' do
        expect(association.macro).to eq(:belongs_to)
        expect(association.name).to eq(:user)
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
