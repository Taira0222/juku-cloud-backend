require "rails_helper"

RSpec.describe Invites::Validator, type: :service do
  describe ".call" do
    subject(:call) { described_class.call(token) }

    context "when the invite exists and is valid" do
      let(:token) { "valid_token" }
      let!(:invite) { create(:invite, raw_token: token) }

      it "returns the invite" do
        expect(call).to eq(invite)
      end
    end

    context "when invite does not exist" do
      let(:token) { "not_found_token" }
      it { expect { call }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context "when invite is expired" do
      let(:token) { "expired_token" }
      # 有効期限切れのinvite を作成
      let!(:invite) do
        create(:invite, raw_token: token).tap do |inv|
          inv.update_column(:expires_at, 1.hour.ago)
        end
      end
      it { expect { call }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context "when invite is exhausted" do
      let(:token) { "used_token" }
      let!(:invite) do
        create(:invite, raw_token: token, uses_count: 5, max_uses: 5)
      end
      it { expect { call }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end
