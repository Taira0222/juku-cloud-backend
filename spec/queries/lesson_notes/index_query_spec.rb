require "rails_helper"

RSpec.describe LessonNotes::IndexQuery, type: :query do
  describe ".call" do
    let!(:school) { create(:school) }
    let!(:created_by) { create(:admin_user) }
    let!(:student) { create(:student, school: school) }
    let!(:class_subject1) { create(:class_subject, name: "english") }
    let!(:class_subject2) { create(:class_subject, name: "japanese") }
    let!(:student_class_subject1) do
      create(
        :student_class_subject,
        student: student,
        class_subject: class_subject1
      )
    end
    let!(:student_class_subject2) do
      create(
        :student_class_subject,
        student: student,
        class_subject: class_subject2
      )
    end
    let!(:lesson_note1) do
      create(
        :lesson_note,
        student_class_subject: student_class_subject1,
        created_by: created_by,
        created_by_name: created_by.name
      )
    end

    let!(:lesson_note2) do
      create(
        :lesson_note,
        student_class_subject: student_class_subject2,
        created_by: created_by,
        created_by_name: created_by.name
      )
    end

    subject(:call) do
      described_class.call(school: school, index_params: index_params)
    end

    context "valid params" do
      let(:index_params) { { studentId: student.id, page: 1, perPage: 10 } }
      context "with last_updated_by" do
        let!(:last_updated_by) { create(:admin_user) }
        let!(:lesson_note3) do
          create(
            :lesson_note,
            title: "note 3",
            student_class_subject: student_class_subject1,
            created_by: created_by,
            created_by_name: created_by.name,
            last_updated_by: last_updated_by,
            last_updated_by_name: last_updated_by.name
          )
        end
        let!(:lesson_notes) do
          create_list(
            :lesson_note,
            20,
            title: "extra note",
            student_class_subject: student_class_subject1,
            created_by: created_by,
            created_by_name: created_by.name
          )
        end

        it "returns lesson notes with associations" do
          result = call
          expect(result).to include(lesson_note1, lesson_note2, lesson_note3)
          expect(result.size).to eq(10) # ページネーションの確認
          # lesson_note1の確認
          expect(result.first.created_by).to eq(created_by)
          expect(result.first.student_class_subject).to eq(
            student_class_subject1
          )
          expect(result.first.student_class_subject.class_subject).to eq(
            class_subject1
          )
          expect(result.first.last_updated_by).to eq(nil)
          # lesson_note3の確認
          expect(result.third.created_by).to eq(created_by)
          expect(result.third.student_class_subject).to eq(
            student_class_subject1
          )
          expect(result.third.student_class_subject.class_subject).to eq(
            class_subject1
          )
          expect(result.third.last_updated_by).to eq(last_updated_by)
        end

        it "returns lesson note3 with search keyword" do
          index_params[:searchKeyword] = "note 3"
          result = call
          expect(result).to match_array([ lesson_note3 ])
        end

        it "returns lesson note1 and lesson note2 without last_updated_by" do
          index_params[:searchKeyword] = "lesson"
          result = call
          expect(result).to match_array([ lesson_note1, lesson_note2 ])
        end

        it "does not return lesson notes with a different search keyword" do
          index_params[:searchKeyword] = "hoge"
          result = call
          expect(result).to be_empty
        end

        it "returns lesson notes sorted by expire_date asc" do
          lesson_note1.update!(expire_date: Date.current - 10.days)
          lesson_note2.update!(expire_date: Date.current - 20.days)
          lesson_note3.update!(expire_date: Date.current - 30.days)
          index_params[:sortBy] = "expire_date_asc"
          result = call
          expect(result.first).to eq(lesson_note3)
        end

        it "returns lesson notes sorted by expire_date desc" do
          lesson_note1.update!(expire_date: Date.current + 10.days)
          lesson_note2.update!(expire_date: Date.current + 20.days)
          lesson_note3.update!(expire_date: Date.current + 30.days)
          index_params[:sortBy] = "expire_date_desc"
          result = call
          expect(result.first).to eq(lesson_note3)
        end

        it "returns lesson notes sorted by id" do
          lesson_note1.update!(expire_date: Date.current + 30.days)
          lesson_note2.update!(expire_date: Date.current + 20.days)
          lesson_note3.update!(expire_date: Date.current + 10.days)
          index_params[:sortBy] = "invalid_option"
          result = call
          expect(result.first).to eq(lesson_note1)
        end

        it "returns lesson notes paginated" do
          index_params[:page] = 2
          index_params[:perPage] = 10
          result = call
          expect(result.size).to eq(10)
          expect(result).not_to include(
            lesson_note1,
            lesson_note2,
            lesson_note3
          )
        end
      end

      context "without last_updated_by" do
        it "returns lesson notes" do
          result = call
          expect(result).to match_array([ lesson_note1, lesson_note2 ])
        end
      end
    end

    context "invalid params" do
      let(:index_params) { { studentId: 0, page: 1, perPage: 10 } }

      it "raises error" do
        expect { call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
