require "rails_helper"

describe Students::Validator, type: :service do
  describe ".call" do
    subject(:call) { described_class.call(id: student.id) }

    context "when the student exists" do
      let(:student) { create(:student) }

      it "returns the student" do
        result = call
        expect(result).to eq(student)
      end
    end

    context "when the student does not exist" do
      it "raises ActiveRecord::RecordNotFound with a custom message" do
        expect { described_class.call(id: -1) }.to raise_error(
          ActiveRecord::RecordNotFound,
          I18n.t("students.errors.not_found")
        )
      end
    end
  end
end
