require "rails_helper"

RSpec.describe "Api::V1::LessonNotes", type: :request do
  let!(:admin_user) { create(:admin_user) }
  let!(:school) { create(:school, owner: admin_user) }
  let!(:teacher) { create(:user, school: school) }
  let!(:other_admin_user) { create(:admin_user) }
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
      let(:index_params) do
        {
          student_id: student.id,
          subject_id: class_subject.id,
          page: 1,
          perPage: 10
        }
      end
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
            student_id: 0
          }
        )
        expect(response).to have_http_status(:not_found)
      end

      it "returns 400 when subject_id is missing" do
        get_with_auth(
          api_v1_lesson_notes_path,
          admin_user,
          params: {
            student_id: student.id,
            page: 1,
            perPage: 10
          }
        )
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "an authenticated teacher" do
      let(:index_params) do
        {
          student_id: student.id,
          subject_id: class_subject.id,
          page: 1,
          perPage: 10
        }
      end
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
            student_id: other_student.id,
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
            student_id: student2.id,
            page: 1,
            perPage: 10
          }
        )
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "an unauthenticated user" do
      it "returns 401 Unauthorized" do
        get api_v1_lesson_notes_path, params: { student_id: student.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /create" do
    context "an authenticated admin user" do
      context "with valid parameters" do
        let!(:create_params) do
          {
            student_id: student.id,
            subject_id: class_subject.id,
            title: "Lesson Note Title",
            description: "Lesson Note Description",
            note_type: "homework",
            expire_date: Date.current + 7.days
          }
        end

        it "creates a new lesson note with create parameters" do
          post_with_auth(
            api_v1_lesson_notes_path,
            admin_user,
            params: create_params
          )
          expect(response).to have_http_status(:created)
          expect(json[:title]).to eq("Lesson Note Title")
          expect(json[:description]).to eq("Lesson Note Description")
          expect(json[:note_type]).to eq("homework")
          expect(json[:expire_date]).to eq((Date.current + 7.days).to_s)
          expect(json[:created_by_name]).to eq(admin_user.name)
        end
      end

      context "with invalid parameters" do
        let!(:invalid_params) do
          {
            student_id: student.id,
            subject_id: class_subject.id,
            title: "",
            description: "Lesson Note Description",
            note_type: "homework",
            expire_date: Date.current + 7.days
          }
        end

        it "returns 422 Unprocessable Content with invalid parameters" do
          post_with_auth(
            api_v1_lesson_notes_path,
            admin_user,
            params: invalid_params
          )
          expect(response).to have_http_status(:unprocessable_content)
          expect(json[:errors]).not_to be_empty
        end

        it "returns 400 Bad Request when the student does not exist" do
          invalid_params[:student_id] = 0
          post_with_auth(
            api_v1_lesson_notes_path,
            admin_user,
            params: invalid_params
          )
          expect(response).to have_http_status(:bad_request)
          expect(json[:errors]).not_to be_empty
        end
      end
    end

    context "an authenticated teacher" do
      let!(:create_params) do
        {
          student_id: student.id,
          subject_id: class_subject.id,
          title: "Lesson Note Title",
          description: "Lesson Note Description",
          note_type: "homework",
          expire_date: Date.current + 7.days
        }
      end
      context "with valid parameters" do
        it "creates a new lesson note with create parameters" do
          post_with_auth(
            api_v1_lesson_notes_path,
            teacher,
            params: create_params
          )
          expect(response).to have_http_status(:created)
        end
      end

      context "with invalid parameters" do
        it "returns 403 when accessing a student from another school" do
          create_params[:student_id] = other_student.id
          post_with_auth(
            api_v1_lesson_notes_path,
            teacher,
            params: create_params
          )
          expect(response).to have_http_status(:forbidden)
        end

        it "returns 403 when accessing a student without assignment" do
          create_params[:student_id] = student2.id
          post_with_auth(
            api_v1_lesson_notes_path,
            teacher,
            params: create_params
          )
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "an unauthenticated user" do
      it "returns 401 Unauthorized" do
        post api_v1_lesson_notes_path, params: { student_id: student.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /update" do
    let!(:lesson_note) do
      create(
        :lesson_note,
        student_class_subject: student_class_subject,
        created_by: admin_user,
        created_by_name: admin_user.name
      )
    end

    context "an authenticated admin user" do
      context "with valid parameters" do
        let!(:update_params) do
          {
            id: lesson_note.id,
            student_id: student.id,
            subject_id: class_subject.id,
            title: "Updated Lesson Note Title",
            description: "Updated Lesson Note Description",
            note_type: "lesson",
            expire_date: (Date.current + 20.days)
          }
        end

        it "updates the lesson note with update parameters" do
          patch_with_auth(
            api_v1_lesson_note_path(lesson_note),
            admin_user,
            params: update_params
          )
          expect(response).to have_http_status(:ok)
          expect(json[:title]).to eq("Updated Lesson Note Title")
          expect(json[:description]).to eq("Updated Lesson Note Description")
          expect(json[:note_type]).to eq("lesson")
          expect(json[:expire_date]).to eq((Date.current + 20.days).to_s)
          expect(json[:created_by_name]).to eq(admin_user.name)
          expect(json[:last_updated_by_name]).to eq(admin_user.name)
        end
      end

      context "with invalid parameters" do
        let!(:invalid_params) do
          {
            id: lesson_note.id,
            student_id: student.id,
            subject_id: class_subject.id,
            title: "",
            description: "Updated Lesson Note Description",
            note_type: "homework",
            expire_date: Date.current + 14.days
          }
        end

        it "returns 422 Unprocessable Content with invalid parameters" do
          patch_with_auth(
            api_v1_lesson_note_path(lesson_note),
            admin_user,
            params: invalid_params
          )
          expect(response).to have_http_status(:unprocessable_content)
          expect(json[:errors]).not_to be_empty
        end

        it "returns 400 Bad Request when the student does not exist" do
          invalid_params[:student_id] = 0
          patch_with_auth(
            api_v1_lesson_note_path(lesson_note),
            admin_user,
            params: invalid_params
          )
          expect(response).to have_http_status(:bad_request)
          expect(json[:errors]).not_to be_empty
        end
      end
    end

    context "an authenticated teacher" do
      let!(:update_params) do
        {
          id: lesson_note.id,
          student_id: student.id,
          subject_id: class_subject.id,
          title: "Updated Lesson Note Title",
          description: "Updated Lesson Note Description",
          note_type: "lesson",
          expire_date: (Date.current + 20.days)
        }
      end
      context "with valid parameters" do
        it "updates the lesson note with update parameters" do
          patch_with_auth(
            api_v1_lesson_note_path(lesson_note),
            teacher,
            params: update_params
          )
          expect(response).to have_http_status(:ok)
          expect(json[:created_by_name]).to eq(admin_user.name)
          expect(json[:last_updated_by_name]).to eq(teacher.name)
        end
      end

      context "with invalid parameters" do
        it "returns 403 when accessing a student from another school" do
          update_params[:student_id] = other_student.id
          patch_with_auth(
            api_v1_lesson_note_path(lesson_note),
            teacher,
            params: update_params
          )
          expect(response).to have_http_status(:forbidden)
        end

        it "returns 403 when accessing a student without assignment" do
          update_params[:student_id] = student2.id
          patch_with_auth(
            api_v1_lesson_note_path(lesson_note),
            teacher,
            params: update_params
          )
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "an unauthenticated user" do
      it "returns 401 Unauthorized" do
        patch api_v1_lesson_note_path(lesson_note),
              params: {
                student_id: student.id
              }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
