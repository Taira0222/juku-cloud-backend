# == Schema Information
#
# Table name: lesson_notes
#
#  id                       :bigint           not null, primary key
#  created_by_name          :string           default(""), not null
#  description              :text
#  expire_date              :date             not null
#  last_updated_by_name     :string
#  note_type                :integer          not null
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
#  index_lesson_notes_on_note_type                 (note_type)
#  index_lesson_notes_on_student_class_subject_id  (student_class_subject_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (last_updated_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (student_class_subject_id => student_class_subjects.id)
#
class LessonNote < ApplicationRecord
  belongs_to :student_class_subject, class_name: "Subjects::StudentLink"

  # DBでは nullify だが、アプリケーション上では必須とする
  belongs_to :created_by,
             class_name: "User",
             inverse_of: :lesson_notes_created,
             optional: false
  belongs_to :last_updated_by,
             class_name: "User",
             inverse_of: :lesson_notes_updated,
             optional: true

  # homework_note_type? メソッドが使用できるようになる
  enum :note_type, { homework: 0, lesson: 1, other: 2 }, suffix: true

  validates :title, presence: true, length: { maximum: 50 }
  validates :description, length: { maximum: 500 }
  # user.name の最大長に合わせる
  validates :created_by_name, presence: true, length: { maximum: 50 }
  validates :last_updated_by_name, length: { maximum: 50 }
  validates :expire_date, presence: true
  validates :note_type, presence: true

  # created_by_name は not null制約があるためbefore_validationでセットする
  before_validation :snapshot_creator_name, on: :create
  before_save :snapshot_updater_name

  def expired?
    expire_date < Date.current
  end

  private

  def snapshot_creator_name
    self.created_by_name = created_by&.name if created_by_name.blank?
  end

  def snapshot_updater_name
    self.last_updated_by_name = last_updated_by&.name
  end
end
