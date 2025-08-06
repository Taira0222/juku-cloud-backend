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
#  status         :integer          default(0), not null
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
FactoryBot.define do
  factory :student do
    association :school
    sequence(:student_code) { |n| "S#{format('%04d', n)}" }
    sequence(:name) { |n| "Test Student #{n}" }
    # status はactive
    status { 0 }
    joined_on { Date.current }
    left_on { nil }
    # school_stage は中学生
    school_stage { 1 }
    grade { 1 }
    desired_school { "Stanford University" }
  end
end
