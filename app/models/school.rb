# == Schema Information
#
# Table name: schools
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  school_code :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  owner_id    :bigint           not null
#
# Indexes
#
#  index_schools_on_owner_id     (owner_id)
#  index_schools_on_school_code  (school_code) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => users.id)
#
class School < ApplicationRecord
  # Admin:School 1:1
  belongs_to :owner, class_name: "User"
  # User(teacher): School 1:N
  has_many :teachers,
           -> { where(role: :teacher) },
           class_name: "User",
           foreign_key: :school_id
  # School:Invite 1:N
  has_many :invites, dependent: :destroy
  # School:Student 1:N
  has_many :students, dependent: :destroy

  # Validations
  validates :owner, presence: true
  validates :name, presence: true, length: { maximum: 255 }
end
