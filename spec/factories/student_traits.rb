# == Schema Information
#
# Table name: student_traits
#
#  id          :bigint           not null, primary key
#  category    :integer
#  description :text
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  student_id  :bigint           not null
#
# Indexes
#
#  index_student_traits_on_student_id  (student_id)
#
# Foreign Keys
#
#  fk_rails_...  (student_id => students.id)
#
FactoryBot.define do
  factory :student_trait do
    association :student
    category { 0 } # good
    title { "student Traits " }
    description { "MyText" }
  end
end
