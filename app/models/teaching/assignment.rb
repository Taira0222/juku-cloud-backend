# == Schema Information
#
# Table name: teaching_assignments
#
#  id                       :bigint           not null, primary key
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  student_class_subject_id :bigint           not null
#  user_id                  :bigint           not null
#
# Indexes
#
#  index_teaching_assignments_on_scs_and_user              (student_class_subject_id,user_id) UNIQUE
#  index_teaching_assignments_on_student_class_subject_id  (student_class_subject_id)
#  index_teaching_assignments_on_user_id                   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (student_class_subject_id => student_class_subjects.id)
#  fk_rails_...  (user_id => users.id)
#
class Teaching::Assignment < ApplicationRecord
  self.table_name = "teaching_assignments"

  belongs_to :user
  belongs_to :student_class_subject,
             class_name: "Subjects::StudentLink",
             foreign_key: :student_class_subject_id
end
