# == Schema Information
#
# Table name: students
#
#  id             :bigint           not null, primary key
#  desired_school :string
#  grade          :integer          not null
#  joined_on      :date
#  name           :string           not null
#  school_stage   :integer          not null
#  status         :integer          default("active"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  school_id      :bigint           not null
#
# Indexes
#
#  index_students_on_school_id  (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (school_id => schools.id)
#
class Student < ApplicationRecord
  belongs_to :school

  # 直接の関連付け
  has_many :student_class_subjects,
           class_name: "Subjects::StudentLink",
           dependent: :destroy
  has_many :class_subjects, through: :student_class_subjects

  # Teaching::Assignmentとの直接関連
  has_many :teaching_assignments, through: :student_class_subjects
  has_many :teachers, through: :teaching_assignments, source: :user

  has_many :student_available_days,
           class_name: "Availability::StudentLink",
           dependent: :destroy
  has_many :available_days, through: :student_available_days

  enum :status, { active: 0, inactive: 1, graduated: 2, on_leave: 3 }
  enum :school_stage,
       { elementary_school: 0, junior_high_school: 1, high_school: 2 }

  validates :name, presence: true, length: { maximum: 50 }
  validates :status, presence: true
  validates :joined_on, presence: true
  validates :school_stage, presence: true
  validates :grade, presence: true
  validates :desired_school, length: { maximum: 100 }, allow_blank: true
end
