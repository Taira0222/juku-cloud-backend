# == Schema Information
#
# Table name: available_days
#
#  id         :bigint           not null, primary key
#  name       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :available_day do
    name { 1 }
  end
end
