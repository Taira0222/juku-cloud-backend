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
FactoryBot.define do
  factory :lesson_note do
    association :student_class_subject
    title { "MyString" }
    description { "MyText" }
  end
end
