require "rails_helper"

RSpec.describe "Api::V1::Students", type: :request do
  let!(:admin_user) { create(:user, role: :admin) }
  let!(:teacher) { create(:another_user) }
  let!(:school) { create(:school, owner: admin_user) }
  describe "GET /index" do
    let!(:students) { create_list(:student, 5, school: school) }
    let(:index_params) do
      {
        searchKeyword: nil,
        school_stage: nil,
        grade: nil,
        page: 1,
        perPage: 10
      }
    end

    it "returns a successful response" do
      get_with_auth(api_v1_students_path, admin_user, params: index_params)
      expect(response).to have_http_status(:success)

      # 形を確認
      expect(json).to include(:students, :meta)
      expect(json[:students]).to be_an(Array)
      expect(json[:students].size).to eq(5)
      first = json[:students].first

      # students の中身を確認
      expect(first.keys).to match_array(
        %i[
          id
          name
          status
          school_stage
          grade
          joined_on
          desired_school
          class_subjects
          available_days
          teachers
          teaching_assignments
        ]
      )
      expect(first[:class_subjects]).to all(include(:id, :name))
      expect(first[:available_days]).to all(include(:id, :name))
      expect(first[:teachers]).to all(include(:id, :name, :role))

      # meta の中身を確認
      expect(json[:meta]).to include(
        :total_pages,
        :total_count,
        :current_page,
        :per_page
      )
      expect(json[:meta][:total_pages]).to eq(1)
      expect(json[:meta][:total_count]).to eq(5)
      expect(json[:meta][:current_page]).to eq(1)
      expect(json[:meta][:per_page]).to eq(10)
    end

    it "returns empty array when no students match the search criteria" do
      get_with_auth(
        api_v1_students_path,
        admin_user,
        params: index_params.merge(searchKeyword: "NonExistentName")
      )
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body, symbolize_names: true)

      expect(json_response[:students]).to be_an(Array)
      expect(json_response[:students].size).to eq(0)
      expect(json_response[:meta][:total_count]).to eq(0)
    end
  end

  describe "POST /create" do
    let!(:subject1) { create(:class_subject, :english) }
    let!(:subject2) { create(:class_subject, :japanese) }
    let!(:available_day1) { create(:available_day, :sunday) }
    let!(:available_day2) { create(:available_day, :monday) }
    let!(:teachers) { create_list(:user, 2, role: :teacher, school: school) }

    it "returns forbidden for non-admin users" do
      non_admin_user = create(:user, role: :teacher, school: school)
      post_with_auth(
        api_v1_students_path,
        non_admin_user,
        params: {
          name: "New Student"
        }
      )
      expect(response).to have_http_status(:forbidden)
    end

    context "with valid parameters" do
      let(:valid_params) do
        {
          name: "Test Student",
          status: "active",
          school_stage: "junior_high_school",
          grade: 3,
          joined_on: "2024-01-15",
          desired_school: "Sample High School",
          subject_ids: [ subject1.id, subject2.id ],
          available_day_ids: [ available_day1.id, available_day2.id ],
          assignments: [
            {
              teacher_id: teachers[0].id,
              subject_id: subject1.id,
              day_id: available_day1.id
            },
            {
              teacher_id: teachers[1].id,
              subject_id: subject2.id,
              day_id: available_day2.id
            }
          ]
        }
      end

      before do
        post_with_auth(api_v1_students_path, admin_user, params: valid_params)
      end

      it "creates a new student with valid parameters" do
        expect(response).to have_http_status(:created)

        # 形を確認
        expect(json.keys).to match_array(
          %i[
            id
            name
            status
            school_stage
            grade
            joined_on
            desired_school
            class_subjects
            available_days
            teachers
            teaching_assignments
          ]
        )
        expect(json[:id]).to be_present
        expect(json[:name]).to eq("Test Student")
        expect(json[:status]).to eq("active")
        expect(json[:school_stage]).to eq("junior_high_school")
        expect(json[:grade]).to eq(3)
        expect(json[:joined_on]).to eq("2024-01-15")
        expect(json[:desired_school]).to eq("Sample High School")
        expect(json[:class_subjects].size).to eq(2)
        expect(json[:available_days].size).to eq(2)
        expect(json[:teachers].size).to eq(2)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          name: "Test Student",
          status: "active",
          school_stage: "junior_high_school",
          grade: 3,
          joined_on: "2024-01-15",
          desired_school: "Sample High School",
          subject_ids: [],
          available_day_ids: [ available_day1.id, available_day2.id ],
          assignments: [
            {
              teacher_id: teachers[0].id,
              subject_id: subject1.id,
              day_id: available_day1.id
            },
            {
              teacher_id: teachers[1].id,
              subject_id: subject2.id,
              day_id: available_day2.id
            }
          ]
        }
      end

      before do
        post_with_auth(api_v1_students_path, admin_user, params: invalid_params)
      end

      it "returns errors when subject_ids is empty" do
        expect(response).to have_http_status(:bad_request)
        errors = json[:errors].first
        expect(errors).to include(
          {
            code: "INVALID_ARGUMENT",
            field: "base",
            message: I18n.t("students.errors.subject_ids_empty")
          }
        )
      end
    end
  end

  describe "PATCH /update" do
    let!(:student) { create(:student, school: school) }
    let!(:subject1) { create(:class_subject, :english) }
    let!(:subject2) { create(:class_subject, :japanese) }
    let!(:subject3) { create(:class_subject, :mathematics) }
    let!(:available_day1) { create(:available_day, :sunday) }
    let!(:available_day2) { create(:available_day, :monday) }
    let!(:available_day3) { create(:available_day, :tuesday) }
    let!(:teacher1) { create(:user, :teacher, school: school) }
    let!(:teacher2) { create(:user, :teacher, school: school) }
    let!(:teacher3) { create(:user, :teacher, school: school) }
    let!(:student_class_subject) do
      create(:student_class_subject, student: student, class_subject: subject3)
    end
    let!(:lesson_note) do
      create(
        :lesson_note,
        student_class_subject: student_class_subject,
        created_by: admin_user
      )
    end
    let!(:student_available_day) do
      create(
        :student_available_day,
        student: student,
        available_day: available_day3
      )
    end
    let!(:teaching_assignment) do
      create(
        :teaching_assignment,
        user: teacher3,
        student_class_subject: student_class_subject,
        available_day: available_day3
      )
    end

    it "returns forbidden for non-admin users" do
      non_admin_user = create(:user, role: :teacher, school: school)
      patch_with_auth(
        api_v1_student_path(student.id),
        non_admin_user,
        params: {
          name: "New Name"
        }
      )
      expect(response).to have_http_status(:forbidden)
    end

    context "with valid parameters" do
      let(:valid_params) do
        {
          id: student.id,
          name: "Test Student",
          status: "active",
          school_stage: "junior_high_school",
          grade: 3,
          joined_on: "2024-01-15",
          desired_school: "Sample High School",
          subject_ids: [ subject1.id, subject2.id ],
          available_day_ids: [ available_day1.id, available_day2.id ],
          assignments: [
            {
              teacher_id: teacher1.id,
              subject_id: subject1.id,
              day_id: available_day1.id
            },
            {
              teacher_id: teacher2.id,
              subject_id: subject2.id,
              day_id: available_day2.id
            }
          ]
        }
      end

      it "updates a student with valid parameters" do
        expect(student).to have_attributes(
          class_subject_ids: [ subject3.id ],
          available_day_ids: [ available_day3.id ],
          teacher_ids: [ teacher3.id ],
          lesson_note_ids: [ lesson_note.id ]
        )
        patch_with_auth(
          api_v1_student_path(student.id),
          admin_user,
          params: valid_params
        )
        expect(response).to have_http_status(:ok)

        # 形を確認
        expect(json.keys).to match_array(
          %i[
            id
            name
            status
            school_stage
            grade
            joined_on
            desired_school
            class_subjects
            available_days
            teachers
            teaching_assignments
          ]
        )
        expect(json[:id]).to eq(student.id)
        expect(json[:name]).to eq("Test Student")
        expect(json[:status]).to eq("active")
        expect(json[:school_stage]).to eq("junior_high_school")
        expect(json[:grade]).to eq(3)
        expect(json[:joined_on]).to eq("2024-01-15")
        expect(json[:desired_school]).to eq("Sample High School")
        expect(json[:class_subjects].size).to eq(2)
        expect(json[:available_days].size).to eq(2)
        expect(json[:teachers].size).to eq(2)
        expect(student.reload).not_to have_attributes(
          class_subject_ids: [ subject3.id ],
          available_day_ids: [ available_day3.id ],
          teacher_ids: [ teacher3.id ],
          lesson_note_ids: [ lesson_note.id ]
        )
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          name: "Test Student",
          status: "active",
          school_stage: "junior_high_school",
          grade: 3,
          joined_on: "2024-01-15",
          desired_school: "Sample High School",
          subject_ids: [],
          available_day_ids: [ available_day1.id, available_day2.id ],
          assignments: [
            {
              teacher_id: teacher1.id,
              subject_id: subject1.id,
              day_id: available_day1.id
            },
            {
              teacher_id: teacher2.id,
              subject_id: subject2.id,
              day_id: available_day2.id
            }
          ]
        }
      end

      before do
        patch_with_auth(
          api_v1_student_path(student.id),
          admin_user,
          params: invalid_params
        )
      end

      it "returns errors when subject_ids is empty" do
        expect(response).to have_http_status(:bad_request)
        errors = json[:errors].first
        expect(errors).to include(
          {
            code: "INVALID_ARGUMENT",
            field: "base",
            message: I18n.t("students.errors.subject_ids_empty")
          }
        )
      end
    end
  end
  describe "DELETE /destroy" do
    let!(:student) { create(:student, school: school) }

    it "deletes the student" do
      expect {
        delete_with_auth(api_v1_student_path(student.id), admin_user)
      }.to change(Student, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "returns not found when student does not exist" do
      delete_with_auth(api_v1_student_path(0), admin_user)
      expect(response).to have_http_status(:not_found)
    end

    it "returns forbidden for non-admin users" do
      non_admin_user = create(:user, role: :teacher, school: school)
      delete_with_auth(api_v1_student_path(student.id), non_admin_user)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
