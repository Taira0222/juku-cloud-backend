# == Schema Information
#
# Table name: schools
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  school_code :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  owner_id    :bigint           not null
#
# Indexes
#
#  index_schools_on_owner_id     (owner_id)
#  index_schools_on_school_code  (school_code) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => users.id)
#
FactoryBot.define do
  factory :school do
    owner { nil }
    name { "MyString" }
    school_code { "MyString" }
  end
end
