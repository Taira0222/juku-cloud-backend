# == Schema Information
#
# Table name: available_days
#
#  id         :bigint           not null, primary key
#  name       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class AvailableDay < ApplicationRecord
  enum :name { sunday: 0, monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5, saturday: 6 }
  validates :name, presence: true, uniqueness: true
end
