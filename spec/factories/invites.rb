# == Schema Information
#
# Table name: invites
#
#  id           :bigint           not null, primary key
#  expires_at   :datetime         not null
#  max_uses     :integer          default(1), not null
#  role         :integer          default("teacher"), not null
#  token_digest :string           not null
#  used_at      :datetime
#  uses_count   :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  school_id    :bigint           not null
#
# Indexes
#
#  index_invites_on_school_id     (school_id)
#  index_invites_on_token_digest  (token_digest) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (school_id => schools.id)
#
FactoryBot.define do
  factory :invite do
    association :school
    role { :teacher }
    max_uses { 1 }
    uses_count { 0 }
    expires_at { 3.days.from_now }
    # DBに保存されない一時的な属性
    transient { raw_token { SecureRandom.hex(10) } }

    token_digest { Invite.digest(raw_token) }

    # テストで raw_token をinvite.raw_tokenのように使えるようにする。
    after(:build) do |invite, evaluator|
      invite.define_singleton_method(:raw_token) { evaluator.raw_token }
    end
  end
end
