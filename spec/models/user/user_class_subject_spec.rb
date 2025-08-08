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
require 'rails_helper'

RSpec.describe UserClassSubject, type: :model do
   describe 'associations' do
    let(:association) do
      described_class.reflect_on_association(target)
    end

    context 'user association' do
      let(:target) { :user }
      it "belongs to user" do
        expect(association.macro).to eq :belongs_to
        expect(association.class_name).to eq 'User'
      end
    end

    context 'class_subject association' do
      let(:target) { :class_subject }
      it "belongs to class_subject" do
        expect(association.macro).to eq :belongs_to
        expect(association.class_name).to eq 'ClassSubject'
      end
    end
  end
end
