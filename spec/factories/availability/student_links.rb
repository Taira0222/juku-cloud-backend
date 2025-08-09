# == Schema Information
#
# Table name: student_available_days
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  available_day_id :bigint           not null
#  student_id       :bigint           not null
#
# Indexes
#
#  idx_on_student_id_available_day_id_b42ed887dc     (student_id,available_day_id) UNIQUE
#  index_student_available_days_on_available_day_id  (available_day_id)
#  index_student_available_days_on_student_id        (student_id)
#
# Foreign Keys
#
#  fk_rails_...  (available_day_id => available_days.id)
#  fk_rails_...  (student_id => students.id)
#
FactoryBot.define do
  factory :student_available_day, class: "Availability::StudentLink" do
    association :student
    association :available_day
  end
end
