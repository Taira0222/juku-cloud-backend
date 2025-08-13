require "rails_helper"

RSpec.describe Invites::TokenGenerate, type: :service do
  describe ".call" do
    subject(:call) { described_class.call(school) }
    let(:school) { create(:school) }

    context "when the school is valid" do
      it "generates a new invite token" do
        result = call
        expect(result).to include(:raw_token)
      end

      it "creates a new invite record" do
        expect { call }.to change(Invite, :count).by(1)
      end
    end

    context "when the school is invalid" do
      let(:school) { nil }
      it "does not generate a new invite token" do
        expect { call }.to raise_error(
          Invites::TokenGenerate::TokenGenerateError
        )
      end
    end
  end
end
