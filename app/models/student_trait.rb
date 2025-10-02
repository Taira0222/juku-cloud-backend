# == Schema Information
#
# Table name: student_traits
#
#  id          :bigint           not null, primary key
#  category    :integer
#  description :text
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  student_id  :bigint           not null
#
# Indexes
#
#  index_student_traits_on_student_id  (student_id)
#
# Foreign Keys
#
#  fk_rails_...  (student_id => students.id)
#
class StudentTrait < ApplicationRecord
  belongs_to :student

  # good_category? メソッドが使用できるようになる
  enum :category, { good: 0, careful: 1 }, suffix: true

  validates :title, presence: true, length: { maximum: 50 }
  validates :description, length: { maximum: 500 }
end
