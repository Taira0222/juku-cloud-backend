# == Schema Information
#
# Table name: teaching_assignments
#
#  id              :bigint           not null, primary key
#  started_on      :date
#  teaching_status :boolean
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  student_id      :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_teaching_assignments_on_student_id  (student_id)
#  index_teaching_assignments_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (student_id => students.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :teaching_assignment do
    association :user
    association :student
    started_on { Time.current }
    teaching_status { true }
  end
end
