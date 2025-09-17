require "rails_helper"

RSpec.describe Invites::TokenGenerate, type: :service do
  describe ".call" do
    subject(:call) { described_class.call(school) }
    let(:school) { create(:school) }

    context "when the school is valid" do
      it "generates a new invite token" do
        result = call
        expect(result).to be_a(String)
        expect(result.length).to be >= 43 # SecureRandom.urlsafe_base64(32)の長さ
      end

      it "creates a new invite record" do
        expect { call }.to change(Invite, :count).by(1)
      end
    end

    context "when the school is invalid" do
      let(:school) { nil }
      it "does not generate a new invite token" do
        expect { call }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
