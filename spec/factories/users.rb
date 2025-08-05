# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  allow_password_change  :boolean          default(FALSE)
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  grade                  :integer
#  graduated_university   :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  name                   :string           default(""), not null
#  provider               :string           default("email"), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default("teacher"), not null
#  school_stage           :integer
#  sign_in_count          :integer          default(0), not null
#  tokens                 :json
#  uid                    :string           default(""), not null
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  school_id              :bigint
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_school_id             (school_id)
#  index_users_on_uid_and_provider      (uid,provider) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (school_id => schools.id)
#
FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Test User #{n}" }
    sequence(:email) { |n| "test#{n}@example.com" }
    password { "password" }
    password_confirmation { "password" }
    confirmed_at { Time.current }
    confirmation_sent_at { Time.current }
    association :school # school との関連を設定
    role { :teacher }
    school_stage { :bachelor }
    grade { 1 }
    graduated_university { "University of Example" }

    trait :unconfirmed do
      confirmation_token { SecureRandom.hex(10) }
      confirmed_at { nil }
    end
  end

  factory :admin_user, parent: :user do
    sequence(:name) { |n| "Admin User #{n}" }
    sequence(:email) { |n| "admin#{n}@example.com" }
    role { :admin }
    school { nil } # 管理者は学校に属さない
    school_stage { nil }
    grade { nil }
    graduated_university { nil }
  end
end
