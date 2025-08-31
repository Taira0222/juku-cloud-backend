# == Schema Information
#
# Table name: student_class_subjects
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  class_subject_id :bigint           not null
#  student_id       :bigint           not null
#
# Indexes
#
#  idx_on_student_id_class_subject_id_c0e296835a     (student_id,class_subject_id) UNIQUE
#  index_student_class_subjects_on_class_subject_id  (class_subject_id)
#  index_student_class_subjects_on_student_id        (student_id)
#
# Foreign Keys
#
#  fk_rails_...  (class_subject_id => class_subjects.id)
#  fk_rails_...  (student_id => students.id)
#
class Subjects::StudentLink < ApplicationRecord
  self.table_name = "student_class_subjects"

  belongs_to :student
  belongs_to :class_subject

  # Teaching::Assignmentとの関連を追加
  has_many :teaching_assignments,
           class_name: "Teaching::Assignment",
           foreign_key: :student_class_subject_id,
           dependent: :destroy
end
