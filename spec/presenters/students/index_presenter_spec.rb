require "rails_helper"

RSpec.describe Students::IndexPresenter do
  describe "#as_json" do
    let(:student1) { instance_double(Student) }
    let(:student2) { instance_double(Student) }

    # Presenterが各studentに渡すas_jsonのオプションを固定
    let(:expected_options) do
      {
        only: %i[id name status school_stage grade desired_school joined_on],
        include: {
          class_subjects: {
            only: %i[id name]
          },
          available_days: {
            only: %i[id name]
          },
          teachers: {
            only: %i[id name role],
            include: {
              teachable_subjects: {
                only: %i[id name]
              },
              workable_days: {
                only: %i[id name]
              }
            }
          }
        }
      }
    end

    context "1 page / per=1" do
      # ページング情報を持った配列（中身はダブル）を作る
      let(:students_page) do
        Kaminari.paginate_array([ student1, student2 ]).page(1).per(1)
      end
      let(:presenter) { described_class.new(students_page) }

      it "delegates as_json to each student with expected_options and returns the results in an array, along with meta" do
        # 1ページ目なのでstudent1だけがmap対象になる想定
        allow(student1).to receive(:as_json).with(expected_options).and_return(
          { "id" => 1, "name" => "Alice" }
        )

        json = presenter.as_json

        expect(json).to have_key(:students)
        expect(json).to have_key(:meta)

        # students配列：1ページ目なので1件だけ
        expect(json[:students]).to eq([ { "id" => 1, "name" => "Alice" } ])

        # meta：Kaminariに一致
        expect(json[:meta]).to eq(
          total_pages: 2, # 2件 / per=1
          total_count: 2,
          current_page: 1,
          per_page: 1
        )
      end

      it "calls as_json on each student with expected_options (verification)" do
        expect(student1).to receive(:as_json).with(expected_options).and_return(
          {}
        )
        # 1ページ目なのでstudent2は呼ばれない（呼ばせたい場合はpage(1).per(2)にする）
        expect(student2).not_to receive(:as_json)

        presenter.as_json
      end
    end

    context "empty page" do
      let(:empty_page) { Kaminari.paginate_array([]).page(1).per(10) }

      it "returns an empty students array and meta with zero values" do
        json = described_class.new(empty_page).as_json

        expect(json[:students]).to eq([])
        expect(json[:meta]).to eq(
          total_pages: 0,
          total_count: 0,
          current_page: 1,
          per_page: 10
        )
      end
    end

    context "confirming delegation for two items in one page" do
      let(:two_in_one_page) do
        Kaminari.paginate_array([ student1, student2 ]).page(1).per(2)
      end
      let(:presenter) { described_class.new(two_in_one_page) }

      it "calls as_json on both students with the same options" do
        expect(student1).to receive(:as_json).with(expected_options).and_return(
          { "id" => 1 }
        )
        expect(student2).to receive(:as_json).with(expected_options).and_return(
          { "id" => 2 }
        )

        json = presenter.as_json
        expect(json[:students]).to eq([ { "id" => 1 }, { "id" => 2 } ])
        expect(json[:meta]).to include(
          total_pages: 1,
          total_count: 2,
          current_page: 1,
          per_page: 2
        )
      end
    end
  end
end
