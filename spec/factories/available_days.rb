# == Schema Information
#
# Table name: available_days
#
#  id         :bigint           not null, primary key
#  name       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :available_day do
    name { 0 } # デフォルトはSunday

    trait :sunday             do name { 0 } end
    trait :monday             do name { 1 } end
    trait :tuesday            do name { 2 } end
    trait :wednesday          do name { 3 } end
    trait :thursday           do name { 4 } end
    trait :friday             do name { 5 } end
    trait :saturday           do name { 6 } end
  end
end
