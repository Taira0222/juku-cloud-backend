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
FactoryBot.define do
  factory :invite do
    association :school
    token { SecureRandom.hex(10) }
    role { :teacher }
    max_uses { 1 }
    uses_count { 0 }
    expires_at { Time.current + 7.days }
    used_at { nil }
  end
end
