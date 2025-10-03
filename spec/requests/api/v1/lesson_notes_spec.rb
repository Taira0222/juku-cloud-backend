require "rails_helper"

RSpec.describe "Api::V1::LessonNotes", type: :request do
  let!(:admin_user) { create(:admin_user) }
  let!(:teacher) { create(:user, school: school) }
  let!(:other_admin_user) { create(:admin_user) }
  let!(:school) { create(:school, owner: admin_user) }
  let!(:other_school) { create(:school, owner: other_admin_user) }
  let!(:student) { create(:student, school: school) }
  let!(:student2) { create(:student, school: school) }
  let!(:other_student) { create(:student, school: other_school) }
  let!(:class_subject) { create(:class_subject) }
  let!(:student_class_subject) do
    create(
      :student_class_subject,
      student: student,
      class_subject: class_subject
    )
  end
  let!(:other_student_class_subject) do
    create(
      :student_class_subject,
      student: other_student,
      class_subject: class_subject
    )
  end
  let!(:teaching_assignment) do
    create(
      :teaching_assignment,
      user: teacher,
      student_class_subject: student_class_subject
    )
  end

  describe "GET /index" do
    let!(:lesson_notes) do
      create_list(
        :lesson_note,
        5,
        student_class_subject: student_class_subject,
        created_by: admin_user,
        created_by_name: admin_user.name
      )
    end

    context "an authenticated admin user" do
      let(:index_params) { { studentId: student.id, page: 1, perPage: 10 } }
      it "returns a successful response with lesson notes" do
        get_with_auth(
          api_v1_lesson_notes_path,
          admin_user,
          params: index_params
        )
        expect(response).to have_http_status(:success)
        expect(json[:lesson_notes].size).to eq(5)
        expect(json[:meta][:total_pages]).to eq(1)
        expect(json[:meta][:total_count]).to eq(5)
        expect(json[:meta][:current_page]).to eq(1)
        expect(json[:meta][:per_page]).to eq(10)
      end

      it "returns 404 when the student does not exist" do
        get_with_auth(
          api_v1_lesson_notes_path,
          admin_user,
          params: {
            studentId: 0
          }
        )
        expect(response).to have_http_status(:not_found)
      end
    end

    context "an authenticated teacher" do
      let(:index_params) { { studentId: student.id, page: 1, perPage: 10 } }
      it "returns a successful response with lesson notes" do
        get_with_auth(api_v1_lesson_notes_path, teacher, params: index_params)
        expect(response).to have_http_status(:success)
        expect(json[:lesson_notes].size).to eq(5)
        expect(json[:meta][:total_pages]).to eq(1)
        expect(json[:meta][:total_count]).to eq(5)
        expect(json[:meta][:current_page]).to eq(1)
        expect(json[:meta][:per_page]).to eq(10)
      end

      it "returns 403 when accessing a student from another school" do
        get_with_auth(
          api_v1_lesson_notes_path,
          teacher,
          params: {
            studentId: other_student.id,
            page: 1,
            perPage: 10
          }
        )
        expect(response).to have_http_status(:forbidden)
      end

      it "returns 403 when accessing a student without assignment" do
        get_with_auth(
          api_v1_lesson_notes_path,
          teacher,
          params: {
            studentId: student2.id,
            page: 1,
            perPage: 10
          }
        )
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "an unauthenticated user" do
      it "returns 401 Unauthorized" do
        get api_v1_lesson_notes_path, params: { studentId: student.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
