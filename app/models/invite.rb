# == Schema Information
#
# Table name: invites
#
#  id         :bigint           not null, primary key
#  expires_at :datetime         not null
#  max_uses   :integer          default(1), not null
#  role       :integer          default("teacher"), not null
#  token      :string           not null
#  used_at    :datetime
#  uses_count :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  school_id  :bigint           not null
#
# Indexes
#
#  index_invites_on_school_id  (school_id)
#  index_invites_on_token      (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (school_id => schools.id)
#
class Invite < ApplicationRecord
  # school:Invite 1:N
  belongs_to :school
  # Invite:User 1:1
  has_one :user

  enum :role, { teacher: 0, admin: 1 }, suffix: true

  validates :token, presence: true, uniqueness: true
  # role はteacher or admin のみ受け付ける
  validates :role, presence: true, inclusion: { in: roles.keys }
  validates :max_uses, presence: true
  validates :expires_at, presence: true, comparison: { greater_than: -> { Time.current } }
end
