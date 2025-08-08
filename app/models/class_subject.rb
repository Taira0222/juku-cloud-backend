# == Schema Information
#
# Table name: class_subjects
#
#  id         :bigint           not null, primary key
#  name       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ClassSubject < ApplicationRecord
  # User:ClassSubject N:N
  has_many :user_class_subjects, dependent: :destroy
  has_many :users, through: :user_class_subjects
  # Student:ClassSubject N:N
  has_many :student_class_subjects, dependent: :destroy
  has_many :students, through: :student_class_subjects
  
  enum :name, {
    english: 0,
    japanese: 1,
    mathematics: 2,
    science: 3,
    social_studies: 4,
    physical_education: 5,
    art: 6,
    music: 7,
    technology_home_economics: 8
  }, suffix: true
  validates :name, presence: true, uniqueness: true
end
