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
require "rails_helper"

RSpec.describe School, type: :model do
  describe "validations" do
    let(:school) { build(:school) }

    it "is valid with valid attributes" do
      expect(school).to be_valid
    end

    it "is not valid without a name" do
      school.name = nil
      expect(school).not_to be_valid
    end

    it "is valid with a name less than 255 characters" do
      school.name = "a" * 254
      expect(school).to be_valid
    end

    it "is not valid with a name longer than 255 characters" do
      school.name = "a" * 256
      expect(school).not_to be_valid
    end

    it "is not valid without a school_code" do
      school.school_code = nil
      expect(school).not_to be_valid
    end

    it "is not valid with a duplicate school_code" do
      create(:school, school_code: "SCHOOL001")
      school.school_code = "SCHOOL001"
      expect(school).not_to be_valid
    end

    it "is not valid without an owner" do
      school.owner = nil
      expect(school).not_to be_valid
    end
  end

  describe "associations" do
    let(:association) { described_class.reflect_on_association(target) }

    context "owner association" do
      let(:target) { :owner }
      it { expect(association.macro).to eq :belongs_to }
      it { expect(association.class_name).to eq "User" }
    end

    context "teachers association" do
      let(:target) { :teachers }
      it { expect(association.macro).to eq :has_many }
      it { expect(association.class_name).to eq "User" }
    end

    context "invites association" do
      let(:target) { :invites }
      it { expect(association.macro).to eq :has_many }
      it { expect(association.class_name).to eq "Invite" }
    end
  end
end
