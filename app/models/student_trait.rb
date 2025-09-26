# == Schema Information
#
# Table name: student_traits
#
#  id                   :bigint           not null, primary key
#  category             :integer
#  created_by_name      :string           default(""), not null
#  description          :text
#  last_updated_by_name :string
#  title                :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  created_by_id        :bigint
#  last_updated_by_id   :bigint
#  student_id           :bigint           not null
#
# Indexes
#
#  index_student_traits_on_created_by_id       (created_by_id)
#  index_student_traits_on_last_updated_by_id  (last_updated_by_id)
#  index_student_traits_on_student_id          (student_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (last_updated_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (student_id => students.id)
#
class StudentTrait < ApplicationRecord
  belongs_to :student
  # DBでは nullify だが、アプリケーション上では必須とする
  belongs_to :created_by,
             class_name: "User",
             inverse_of: :student_traits_created,
             optional: false
  belongs_to :last_updated_by,
             class_name: "User",
             inverse_of: :student_traits_updated,
             optional: true

  # good_category? メソッドが使用できるようになる
  enum :category, { good: 0, careful: 1 }, suffix: true

  validates :title, presence: true, length: { maximum: 50 }
  validates :description, length: { maximum: 1000 }
  # user.name の最大文字数に合わせる
  validates :created_by_name, presence: true, length: { maximum: 50 }
  validates :last_updated_by_name, length: { maximum: 50 }

  # created_by_name は not null制約があるためbefore_validationでセットする
  before_validation :snapshot_creator_name, on: :create
  before_save :snapshot_updater_name

  private

  def snapshot_creator_name
    self.created_by_name = created_by&.name if created_by_name.blank?
  end

  def snapshot_updater_name
    self.last_updated_by_name = last_updated_by&.name
  end
end
