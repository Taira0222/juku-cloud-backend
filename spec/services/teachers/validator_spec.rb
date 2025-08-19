RSpec.describe Teachers::Validator do
  describe ".call" do
    subject(:call) { described_class.call(id: id) }

    context "when teacher exists" do
      let(:teacher) { create(:user) }
      let(:id) { teacher.id }

      it "returns a successful result" do
        result = call
        expect(result.ok?).to be true
        expect(result.teacher).to eq(teacher)
        expect(result.status).to eq(:ok)
        expect(result.error).to be_nil
      end
    end

    context "when teacher does not exist" do
      let(:id) { -1 }

      it "returns a not found result" do
        result = call
        expect(result.ok?).to be false
        expect(result.teacher).to be_nil
        expect(result.status).to eq(:not_found)
        expect(result.error).to eq(I18n.t("teachers.errors.not_found"))
      end
    end

    context "when trying to delete an admin" do
      let(:admin) { create(:user, :admin) }
      let(:id) { admin.id }

      it "returns a forbidden result" do
        result = call
        expect(result.ok?).to be false
        expect(result.teacher).to eq(admin)
        expect(result.status).to eq(:forbidden)
        expect(result.error).to eq(I18n.t("teachers.errors.delete.admin"))
      end
    end
  end
end
