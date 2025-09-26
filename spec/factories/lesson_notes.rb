# == Schema Information
#
# Table name: lesson_notes
#
#  id                       :bigint           not null, primary key
#  created_by_name          :string           default(""), not null
#  description              :text
#  expire_date              :date             not null
#  last_updated_by_name     :string
#  title                    :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  created_by_id            :bigint
#  last_updated_by_id       :bigint
#  student_class_subject_id :bigint           not null
#
# Indexes
#
#  index_lesson_notes_on_created_by_id             (created_by_id)
#  index_lesson_notes_on_expire_date               (expire_date)
#  index_lesson_notes_on_last_updated_by_id        (last_updated_by_id)
#  index_lesson_notes_on_student_class_subject_id  (student_class_subject_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (last_updated_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (student_class_subject_id => student_class_subjects.id)
#
FactoryBot.define do
  factory :lesson_note do
    association :student_class_subject
    association :created_by, factory: :user
    title { "lesson note title" }
    description { "lesson note description" }
    created_by_name { created_by.name }
    expire_date { Date.current + 30.days }
  end
  factory :lesson_note_updated, parent: :lesson_note do
    association :last_updated_by, factory: :user
    last_updated_by_name { last_updated_by.name }
  end
end
