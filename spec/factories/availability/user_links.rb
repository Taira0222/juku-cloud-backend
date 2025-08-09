# == Schema Information
#
# Table name: user_available_days
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  available_day_id :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_user_available_days_on_available_day_id              (available_day_id)
#  index_user_available_days_on_user_id                       (user_id)
#  index_user_available_days_on_user_id_and_available_day_id  (user_id,available_day_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (available_day_id => available_days.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :user_available_day, class: "Availability::UserLink" do
    association :user
    association :available_day
  end
end
