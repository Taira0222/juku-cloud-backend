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
require "rails_helper"

RSpec.describe StudentTrait, type: :model do
  describe "validation" do
    let(:student_trait) { build(:student_trait) }

    it "is valid with valid attributes" do
      expect(student_trait).to be_valid
    end

    it "is not valid without a title" do
      student_trait.title = nil
      expect(student_trait).not_to be_valid
    end

    it "is valid with 50 characters title" do
      student_trait.title = "a" * 50
      expect(student_trait).to be_valid
    end

    it "is not valid with 51 characters title" do
      student_trait.title = "a" * 51
      expect(student_trait).not_to be_valid
    end

    it "is valid even if a description is nil" do
      student_trait.description = nil
      expect(student_trait).to be_valid
    end

    it "is valid with 1000 characters description" do
      student_trait.description = "a" * 1000
      expect(student_trait).to be_valid
    end

    it "is not valid with 1001 characters description" do
      student_trait.description = "a" * 1001
      expect(student_trait).not_to be_valid
    end

    it "is not valid with enum category other than good and careful" do
      expect { student_trait.category = 2 }.to raise_error(ArgumentError)
    end

    it "works snapshot_creator_name before_validation on create" do
      student_trait.created_by_name = nil
      student_trait.valid?
      expect(student_trait.created_by_name).to eq student_trait.created_by.name
    end

    it "is valid even if a last_updated_by_name is nil" do
      student_trait.last_updated_by_name = nil
      expect(student_trait).to be_valid
    end

    it "works snapshot_updater_name before_save" do
      updated_by = create(:user)
      student_trait.last_updated_by = updated_by
      student_trait.save!
      expect(student_trait.last_updated_by_name).to eq updated_by.name
    end
  end
  describe "association" do
    let(:association) { described_class.reflect_on_association(target) }

    context "student association" do
      let(:target) { :student }
      it "belongs to student" do
        expect(association.macro).to eq :belongs_to
        expect(association.options).to be_empty
        expect(association.class_name).to eq "Student"
      end
    end
    context "created_by association" do
      let(:target) { :created_by }
      it "belongs to user" do
        expect(association.macro).to eq :belongs_to
        expect(association.options).to include(
          inverse_of: :student_traits_created
        )
        expect(association.class_name).to eq "User"
      end
    end
    context "last_updated_by association" do
      let(:target) { :last_updated_by }
      it "belongs to user" do
        expect(association.macro).to eq :belongs_to
        expect(association.options).to include(
          inverse_of: :student_traits_updated,
          optional: true
        )
        expect(association.class_name).to eq "User"
      end
    end
  end
end
