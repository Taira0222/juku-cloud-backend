# == Schema Information
#
# Table name: students
#
#  id             :bigint           not null, primary key
#  desired_school :string
#  grade          :integer          not null
#  joined_on      :date
#  left_on        :date
#  name           :string           not null
#  school_stage   :integer          not null
#  status         :integer          default("active"), not null
#  student_code   :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  school_id      :bigint           not null
#
# Indexes
#
#  index_students_on_school_id     (school_id)
#  index_students_on_student_code  (student_code) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (school_id => schools.id)
#
class Student < ApplicationRecord
  belongs_to :school
  # User:Student N:N
  has_many :teaching_assignments, class_name: "Teaching::Assignment", dependent: :destroy
  has_many :users, through: :teaching_assignments
  # Student:ClassSubject N:N
  has_many :student_class_subjects, dependent: :destroy
  has_many :class_subjects, through: :student_class_subjects
  # Student:AvailableDay N:N
  has_many :student_available_days, dependent: :destroy
  has_many :available_days, through: :student_available_days

  enum :status, { active: 0, graduated: 1, quit: 2, paused: 3 }
  enum :school_stage, { elementary_school: 0, junior_high_school: 1, high_school: 2 }

  # Student code format: S followed by 4 digits (e.g., S0001)
  validates :student_code, presence: true, uniqueness: true, format: { with: /\AS\d{4}\z/ }
  validates :name, presence: true, length: { maximum: 50 }
  validates :status, presence: true
  validates :joined_on, presence: true
  validates :school_stage, presence: true
  validates :grade, presence: true
  validates :desired_school, length: { maximum: 100 }, allow_blank: true

  # 退塾日は入塾日以降であることを確認する 自作validate なので単数形
  validate :left_on_after_joined_on

  before_validation :set_student_code, on: :create

  private

    def set_student_code
      last_code = Student.maximum(:student_code)
      last_number = last_code ? last_code.delete_prefix("S").to_i : 0
      self.student_code = format("S%04d", last_number + 1)
    end

    def left_on_after_joined_on
      return if left_on.blank? || joined_on.blank?
      errors.add(:left_on, "は入塾日以降の日付である必要があります") if left_on < joined_on
    end
end
