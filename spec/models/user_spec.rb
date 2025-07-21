require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    context "validates presence and length of name" do
      it "is valid with valid attributes" do
        user = build(:user)
        expect(user).to be_valid
      end

      it "is not valid without a name" do
        user = build(:user, name: nil)
        expect(user).not_to be_valid
      end

      it "is not valid with a name longer than 50 characters" do
        user = build(:user, name: "a" * 51)
        expect(user).not_to be_valid
      end
    end

    context "validates email format and presence" do
      it "is not valid without an email" do
        user = build(:user, email: nil)
        expect(user).not_to be_valid
      end

      it "is not valid with an invalid email format" do
        user = build(:user, email: "invalid_email")
        expect(user).not_to be_valid
      end
    end

    context "validates password presence and length" do
      it "is not valid without a password" do
        user = build(:user, password: nil)
        expect(user).not_to be_valid
      end

      it "is not valid with a password shorter than 6 characters" do
        user = build(:user, password: "short")
        expect(user).not_to be_valid
      end
    end

    context "validates role presence" do
      it "is not valid without a role" do
        user = build(:user, role: nil)
        expect(user).not_to be_valid
      end
    end
  end

  describe "role" do
    it "defaults to teacher" do
      user = build(:user)
      expect(user.role).to eq("teacher")
    end

    it "allows setting role to admin" do
      user = build(:user, role: :admin)
      expect(user.role).to eq("admin")
    end
    # 異常値テスト
    it "does not allow invalid roles" do
      expect { build(:user, role: :invalid_role) }.to raise_error(ArgumentError)
    end
  end

  describe "school_stage" do
    it "defaults to bachelor" do
      user = build(:user)
      expect(user.school_stage).to eq("bachelor")
    end

    it "allows setting school_stage to master" do
      user = build(:user, school_stage: :master)
      expect(user.school_stage).to eq("master")
    end
    # 異常値テスト
    it "does not allow invalid school stages" do
      expect { build(:user, school_stage: :invalid_stage) }.to raise_error(ArgumentError)
    end
  end
end
