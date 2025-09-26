# == Schema Information
#
# Table name: student_traits
#
#  id                   :bigint           not null, primary key
#  category             :integer
#  created_by_name      :string           default(""), not null
#  description          :text
#  last_updated_by_name :string
#  title                :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  created_by_id        :bigint
#  last_updated_by_id   :bigint
#  student_id           :bigint           not null
#
# Indexes
#
#  index_student_traits_on_created_by_id       (created_by_id)
#  index_student_traits_on_last_updated_by_id  (last_updated_by_id)
#  index_student_traits_on_student_id          (student_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (last_updated_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (student_id => students.id)
#
FactoryBot.define do
  factory :student_trait do
    association :student
    association :created_by, factory: :user
    category { 0 } # good
    title { "MyString" }
    description { "MyText" }
    created_by_name { created_by.name }
  end
  factory :student_trait_updated, parent: :student_trait do
    association :last_updated_by, factory: :user
    last_updated_by_name { last_updated_by.name }
  end
end
