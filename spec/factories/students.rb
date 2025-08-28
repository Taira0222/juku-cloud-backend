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
FactoryBot.define do
  factory :student do
    association :school
    sequence(:name) { |n| "Test Student #{n}" }
    # status はactive
    status { 0 }
    joined_on { Date.current }
    # school_stage は中学生
    school_stage { 1 }
    grade { 1 }
    desired_school { "Stanford University" }
  end
end
