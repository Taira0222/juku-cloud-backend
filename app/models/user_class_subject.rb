# == Schema Information
#
# Table name: user_class_subjects
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  class_subject_id :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_user_class_subjects_on_class_subject_id              (class_subject_id)
#  index_user_class_subjects_on_user_id                       (user_id)
#  index_user_class_subjects_on_user_id_and_class_subject_id  (user_id,class_subject_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (class_subject_id => class_subjects.id)
#  fk_rails_...  (user_id => users.id)
#
class UserClassSubject < ApplicationRecord
  belongs_to :user
  belongs_to :class_subject
end
