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

    it "is valid with 500 characters description" do
      student_trait.description = "a" * 500
      expect(student_trait).to be_valid
    end

    it "is not valid with 501 characters description" do
      student_trait.description = "a" * 501
      expect(student_trait).not_to be_valid
    end

    it "is not valid with enum category other than good and careful" do
      expect { student_trait.category = 2 }.to raise_error(ArgumentError)
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
  end
end
