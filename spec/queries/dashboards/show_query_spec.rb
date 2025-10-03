require "rails_helper"

RSpec.describe Dashboards::ShowQuery, type: :query do
  describe ".call" do
    let(:school) { create(:school) }
    let(:student) { create(:student, school: school) }
    let(:class_subject) { create(:class_subject) }
    let!(:student_class_subject) do
      create(
        :student_class_subject,
        student: student,
        class_subject: class_subject
      )
    end
    subject(:call) { described_class.call(school:, id: student.id) }

    it "returns the student" do
      result = call
      expect(result).to eq student
      expect(result.association(:student_class_subjects)).to be_loaded
      expect(
        result.student_class_subjects.first.association(:class_subject)
      ).to be_loaded
    end

    it "returns 404 when student is not found" do
      expect { described_class.call(school:, id: 0) }.to raise_error(
        ActiveRecord::RecordNotFound
      )
    end
  end
end
