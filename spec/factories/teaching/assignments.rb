# == Schema Information
#
# Table name: teaching_assignments
#
#  id                       :bigint           not null, primary key
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  available_day_id         :bigint           not null
#  student_class_subject_id :bigint           not null
#  user_id                  :bigint           not null
#
# Indexes
#
#  idx_assignments_user_subject_day_unique                 (user_id,student_class_subject_id,available_day_id) UNIQUE
#  index_teaching_assignments_on_available_day_id          (available_day_id)
#  index_teaching_assignments_on_scs_and_user              (student_class_subject_id,user_id) UNIQUE
#  index_teaching_assignments_on_student_class_subject_id  (student_class_subject_id)
#  index_teaching_assignments_on_user_id                   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (available_day_id => available_days.id)
#  fk_rails_...  (student_class_subject_id => student_class_subjects.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :teaching_assignment, class: "Teaching::Assignment" do
    association :user
    association :student_class_subject
    association :available_day
  end
end
