# == Schema Information
#
# Table name: lesson_notes
#
#  id                       :bigint           not null, primary key
#  description              :text
#  title                    :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  student_class_subject_id :bigint           not null
#
# Indexes
#
#  index_lesson_notes_on_student_class_subject_id  (student_class_subject_id)
#
# Foreign Keys
#
#  fk_rails_...  (student_class_subject_id => student_class_subjects.id)
#
class LessonNote < ApplicationRecord
  belongs_to :student_class_subject, class_name: "Subjects::StudentLink"

  validates :title, presence: true, length: { maximum: 50 }
  validates :description, length: { maximum: 1000 }
end
