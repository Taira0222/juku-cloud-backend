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
  # User:AvailableDay N:N
  has_many :user_available_days,
           class_name: "Availability::UserLink",
           dependent: :destroy
  has_many :users, through: :user_available_days
  # Student:AvailableDay N:N
  has_many :student_available_days,
           class_name: "Availability::StudentLink",
           dependent: :destroy
  has_many :students, through: :student_available_days

  has_many :teaching_assignments, class_name: "Teaching::Assignment"

  enum :name,
       {
         sunday: 0,
         monday: 1,
         tuesday: 2,
         wednesday: 3,
         thursday: 4,
         friday: 5,
         saturday: 6
       }
  validates :name, presence: true, uniqueness: true
end
