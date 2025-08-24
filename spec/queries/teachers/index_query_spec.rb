require "rails_helper"

RSpec.describe Teachers::IndexQuery, type: :query do
  describe ".call" do
    let!(:user) { create(:user, role: :admin) }
    let!(:school) { create(:school, owner: user) }
    subject(:call) { described_class.call(user, school: school) }

    it "returns the current user and teachers" do
      result = call
      expect(result[:current]).to eq(user)
      # Assuming teachers are associated with the school
      expect(result[:teachers]).to match_array(school.teachers)
    end
  end
end
