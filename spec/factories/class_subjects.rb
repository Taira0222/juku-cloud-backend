# == Schema Information
#
# Table name: class_subjects
#
#  id         :bigint           not null, primary key
#  name       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :class_subject do
    name { 0 } # デフォルトは英語

    trait :english do
      name { 0 }
    end
    trait :japanese do
      name { 1 }
    end
    trait :mathematics do
      name { 2 }
    end
    trait :science do
      name { 3 }
    end
    trait :social_studies do
      name { 4 }
    end
  end
end
