RSpec.describe Teachers::Validator do
  describe ".call" do
    subject(:call) { described_class.call(id: id) }

    context "when teacher exists" do
      let(:teacher) { create(:user) }
      let(:id) { teacher.id }

      it "returns a successful result" do
        result = call
        expect(result).to eq(teacher)
      end
    end

    context "when teacher does not exist" do
      let(:id) { -1 }

      it "raise RecordNotFound" do
        expect { call }.to raise_error(
          ActiveRecord::RecordNotFound,
          I18n.t("teachers.errors.not_found")
        )
      end
    end

    context "when trying to delete an admin" do
      let(:admin) { create(:user, :admin) }
      let(:id) { admin.id }

      it "raise ForbiddenError" do
        expect { call }.to raise_error(
          ForbiddenError,
          I18n.t("teachers.errors.delete.admin")
        )
      end
    end
  end
end
