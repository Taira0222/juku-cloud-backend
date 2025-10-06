require "rails_helper"

RSpec.describe "Api::V1::Dashboards", type: :request do
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
  let!(:teaching_assignment) do
    create(
      :teaching_assignment,
      user: teacher,
      student_class_subject: student_class_subject
    )
  end

  describe "GET /show" do
    context "an authenticated admin user" do
      it "returns a successful response with dashboard data" do
        get_with_auth api_v1_dashboard_path(id: student.id), admin_user
        expect(response).to have_http_status(:success)
        expect(json).to eq(
          id: student.id,
          name: student.name,
          status: student.status,
          school_stage: student.school_stage,
          grade: student.grade,
          desired_school: student.desired_school,
          joined_on: student.joined_on.iso8601,
          class_subjects: [ { id: class_subject.id, name: class_subject.name } ]
        )
      end

      it "returns 404 when accessing a student from another school" do
        get_with_auth api_v1_dashboard_path(id: other_student.id), admin_user
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 when the student does not exist" do
        get_with_auth api_v1_dashboard_path(id: 0), admin_user
        expect(response).to have_http_status(:not_found)
      end
    end

    context "an authenticated teacher" do
      it "returns a successful response with dashboard data" do
        get_with_auth api_v1_dashboard_path(id: student.id), teacher
        expect(response).to have_http_status(:success)
        expect(json).to eq(
          id: student.id,
          name: student.name,
          status: student.status,
          school_stage: student.school_stage,
          grade: student.grade,
          desired_school: student.desired_school,
          joined_on: student.joined_on.iso8601,
          class_subjects: [ { id: class_subject.id, name: class_subject.name } ]
        )
      end

      it "returns 403 when accessing a student from another school" do
        get_with_auth api_v1_dashboard_path(id: other_student.id), teacher
        expect(response).to have_http_status(:forbidden)
      end

      it "returns 403 when accessing a student not assigned to the teacher" do
        get_with_auth api_v1_dashboard_path(id: student2.id), teacher
        expect(response).to have_http_status(:forbidden)
      end

      it "returns 400 when the student does not exist" do
        get_with_auth api_v1_dashboard_path(id: "invalid"), teacher
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
