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
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_uid_and_provider      (uid,provider) UNIQUE
#
FactoryBot.define do
  factory :user do
    name { "Test User" }
    email { "test@example.com" }
    password { "password" }
    password_confirmation { 'password' }
    confirmed_at { Time.current }
    confirmation_sent_at { Time.current }
    role { :teacher }
    school_stage { :bachelor }
    grade { 1 }
    graduated_university { "University of Example" }

    trait :admin do
      confirmed_at { Time.current }
      confirmation_sent_at { Time.current }
      role { :admin }
      school_stage { nil }
      grade { nil }
      graduated_university { nil }
    end

    trait :confirmed do
      role { :admin }
      confirmed_at { Time.current }
      confirmation_sent_at { Time.current }
    end

    trait :unconfirmed do
      role { :admin }
      confirmation_token { 'test_confirm_token12345' }
      confirmed_at { nil }
      confirmation_sent_at { Time.current }
    end
  end
end
