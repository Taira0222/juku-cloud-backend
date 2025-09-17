RSpec.describe Teachers::Updater do
  describe ".call" do
    subject(:call) { described_class.call(teacher: teacher, attrs: attrs) }
    # 必要な科目、曜日、生徒を定義しておく
    let!(:subjects) do
      %i[english japanese mathematics].each_with_index.map do |trait, i|
        create(:class_subject, trait, id: i + 1)
      end
    end
    let!(:available_days) do
      %i[sunday monday tuesday].each_with_index.map do |trait, i|
        create(:available_day, trait, id: i + 1)
      end
    end

    context "with valid attributes" do
      let!(:teacher) do
        create(
          :user,
          :teacher,
          name: "Old Name",
          employment_status: "inactive",
          class_subject_ids: [],
          available_day_ids: []
        )
      end
      let(:attrs) do
        {
          name: "New Name",
          employment_status: "active",
          subject_ids: [1, 2, 3],
          available_day_ids: [1, 2, 3]
        }
      end

      it "updates the teacher's attributes and returns a successful result" do
        # updater を呼んで更新されることを確認
        result = call
        expect(result).to have_attributes(
          name: "New Name",
          employment_status: "active",
          class_subject_ids: [1, 2, 3],
          available_day_ids: [1, 2, 3]
        )
      end
    end

    context "when arrays are provided (dedupe works)" do
      let(:teacher) { create(:user, :teacher) }
      let(:attrs) do
        {
          name: "Updated Teacher",
          employment_status: "active",
          subject_ids: [1, 1, 2],
          available_day_ids: [2, 2, 3]
        }
      end

      it "sets associations with uniq" do
        result = call
        expect(result).to have_attributes(
          name: "Updated Teacher",
          employment_status: "active",
          class_subject_ids: [1, 2],
          available_day_ids: [2, 3]
        )
      end
    end

    context "when arrays are empty (skip-update spec)" do
      let(:teacher) do
        create(:user, :teacher, class_subject_ids: [1], available_day_ids: [1])
      end
      let(:attrs) do
        {
          name: "Updated Teacher",
          employment_status: "active",
          subject_ids: [], # extract の .presence で nil になり、代入をスキップ
          available_day_ids: []
        }
      end

      it "does not touch associations" do
        result = call
        expect(result).to have_attributes(
          name: "Updated Teacher",
          employment_status: "active",
          class_subject_ids: [1],
          available_day_ids: [1]
        )
      end
    end
    context "returns ArgumentError if invalid enum values are provided" do
      let(:teacher) { create(:user, :teacher) }
      let(:attrs) do
        {
          name: "Updated Teacher",
          employment_status: "invalid_status", # Invalid enum value
          subject_ids: [1, 2],
          available_day_ids: [1, 2]
        }
      end

      it "returns an error result" do
        expect { call }.to raise_error(
          ArgumentError,
          I18n.t("teachers.errors.invalid_argument")
        )
      end
    end
  end
end
