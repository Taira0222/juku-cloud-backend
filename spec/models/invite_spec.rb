# == Schema Information
#
# Table name: invites
#
#  id           :bigint           not null, primary key
#  expires_at   :datetime         not null
#  max_uses     :integer          default(1), not null
#  role         :integer          default("teacher"), not null
#  token_digest :string           not null
#  used_at      :datetime
#  uses_count   :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  school_id    :bigint           not null
#
# Indexes
#
#  index_invites_on_school_id     (school_id)
#  index_invites_on_token_digest  (token_digest) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (school_id => schools.id)
#
require "rails_helper"

RSpec.describe Invite, type: :model do
  describe "validations" do
    let(:invite) { build(:invite) }

    it "is valid with valid attributes" do
      expect(invite).to be_valid
    end

    it "is not valid without a token" do
      invite.token_digest = nil
      expect(invite).not_to be_valid
    end

    it "is not valid with a duplicate token" do
      create(:invite, token_digest: "unique_token")
      invite.token_digest = "unique_token"
      expect(invite).not_to be_valid
    end

    it "is not valid without a school" do
      invite.school = nil
      expect(invite).not_to be_valid
    end

    it "is not valid without max_uses" do
      invite.max_uses = nil
      expect(invite).not_to be_valid
    end

    it "is not valid without a role" do
      invite.role = nil
      expect(invite).not_to be_valid
    end

    it "is not valid without an expiration date" do
      invite.expires_at = nil
      expect(invite).not_to be_valid
    end

    it "is not valid if expires_at is in the past" do
      invite.expires_at = 1.day.ago
      expect(invite).not_to be_valid
    end
  end

  describe "associations" do
    let(:association) { described_class.reflect_on_association(target) }

    context "school association" do
      let(:target) { :school }
      it "belongs to a school" do
        expect(association.macro).to eq(:belongs_to)
        expect(association.class_name).to eq("School")
      end
    end

    context "user association" do
      let(:target) { :user }
      it "has one user" do
        expect(association.macro).to eq(:has_one)
        expect(association.class_name).to eq("User")
      end
    end
  end
end
