require "rails_helper"

RSpec.describe Teachers::IndexPresenter do
  describe "#as_json" do
    let(:current) { instance_double(User) }
    let(:teacher1) { instance_double(User) }
    let(:teacher2) { instance_double(User) }
    # Presenterに渡すデータの構造を定義
    let(:result_hash) { { current: current, teachers: [ teacher1, teacher2 ] } }

    let(:presenter) { described_class.new(result_hash) }

    # Presenterがユーザーに渡すべきas_jsonオプションを共通化
    let(:expected_options) do
      {
        include: {
          students: {
            only: %i[id name status school_stage grade]
          },
          class_subjects: {
            only: %i[id name]
          },
          available_days: {
            only: %i[id name]
          }
        },
        methods: %i[current_sign_in_at]
      }
    end

    it "delegates as_json to current user and each teacher with the same options" do
      # expected_options を引数として使用している
      allow(current).to receive(:as_json).with(expected_options).and_return(
        { "id" => 1 }
      )
      allow(teacher1).to receive(:as_json).with(expected_options).and_return(
        { "id" => 2 }
      )
      allow(teacher2).to receive(:as_json).with(expected_options).and_return(
        { "id" => 3 }
      )
      # Presenterのas_jsonメソッドを呼び出すと、currentユーザーと各teacherのas_jsonが呼ばれ、その結果を集約して返す
      json = presenter.as_json

      expect(json).to eq(
        current_user: {
          "id" => 1
        },
        teachers: [ { "id" => 2 }, { "id" => 3 } ]
      )
    end

    it "calls as_json on current user and each teacher with the expected options" do
      expect(current).to receive(:as_json).with(expected_options).and_return({})
      expect(teacher1).to receive(:as_json).with(expected_options).and_return(
        {}
      )
      expect(teacher2).to receive(:as_json).with(expected_options).and_return(
        {}
      )

      presenter.as_json
    end

    it "works even when teachers array is empty" do
      empty_presenter = described_class.new(current: current, teachers: [])
      allow(current).to receive(:as_json).with(expected_options).and_return(
        { "id" => 1 }
      )

      json = empty_presenter.as_json
      expect(json).to eq(current_user: { "id" => 1 }, teachers: [])
    end
  end
end
