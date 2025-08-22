require "rails_helper"

RSpec.describe "Api::V1::Teachers", type: :request do
  describe "GET /index" do
    let!(:admin_user) { create(:admin_user) }
    let!(:another_admin) { create(:admin_user) }
    let!(:school) { create(:school, owner: admin_user) }
    let!(:teacher) { create(:user, school: school) }
    let!(:student) { create(:student, school: school) }
    let!(:class_subject) { create(:class_subject) }
    let!(:available_day) { create(:available_day) }
    # 中間テーブル
    let!(:teaching_assignment) do
      create(:teaching_assignment, user: teacher, student: student)
    end
    let!(:teaching_assignment_admin) do
      create(:teaching_assignment, user: admin_user, student: student)
    end

    let!(:user_class_subject) do
      create(:user_class_subject, user: teacher, class_subject: class_subject)
    end
    let!(:user_class_subject_admin) do
      create(
        :user_class_subject,
        user: admin_user,
        class_subject: class_subject
      )
    end

    let!(:user_available_day) do
      create(:user_available_day, user: teacher, available_day: available_day)
    end
    let!(:user_available_day_admin) do
      create(
        :user_available_day,
        user: admin_user,
        available_day: available_day
      )
    end

    context "admin signed in" do
      it "returns a successful response" do
        get_with_auth(api_v1_teachers_path, admin_user)
        expect(response).to have_http_status(:success)
      end

      it "returns all teachers for the school" do
        get_with_auth(api_v1_teachers_path, admin_user)
        # JSON を ハッシュに変換
        json_response = JSON.parse(response.body)

        # res_current のrender 情報の確認
        res_current = json_response["current_user"]
        expect(res_current).to include("id" => admin_user.id)
        # res_current のキー情報の確認
        expect(res_current.keys).to include(
          "id",
          "name",
          "role",
          "email",
          "created_at",
          "employment_status",
          "current_sign_in_at",
          "students",
          "class_subjects",
          "available_days"
        )

        res_admin_student = res_current["students"].first
        # res_current がstudent を所有していることの確認
        expect(res_admin_student["id"]).to eq(student.id)
        # res_admin_student の情報の確認
        expect(res_admin_student.keys).to include(
          "id",
          "name",
          "grade",
          "school_stage",
          "student_code"
        )

        res_admin_class_subjects = res_current["class_subjects"]
        expect(res_admin_class_subjects.size).to eq(1)
        expect(res_admin_class_subjects.first).to include("id", "name")

        res_admin_available = res_current["available_days"]
        expect(res_admin_available.size).to eq(1)
        expect(res_admin_available.first).to include("id", "name")

        # teachers の情報の確認
        res_teachers = json_response["teachers"]
        expect(res_teachers.size).to eq(1)

        # 1人目の teacher を定義
        res_teacher = res_teachers.first
        expect(res_teacher).to include(
          "id" => teacher.id,
          "name" => teacher.name
        )

        # res_teacher の学生情報の確認
        res_teacher_student = res_teacher["students"].first
        expect(res_teacher_student).to include(
          "id" => student.id,
          "name" => student.name,
          "grade" => student.grade,
          "school_stage" => student.school_stage,
          "student_code" => student.student_code
        )

        # res_teacher の授業科目情報の確認
        res_teacher_subject = res_teacher["class_subjects"].first
        expect(res_teacher_subject).to include(
          "id" => class_subject.id,
          "name" => class_subject.name
        )

        # res_teacher の利用可能日情報の確認
        res_teacher_available = res_teacher["available_days"].first
        expect(res_teacher_available).to include(
          "id" => available_day.id,
          "name" => available_day.name
        )
      end

      it "does not return teachers from other schools" do
        other_school = create(:school)
        other_teacher = create(:user, school: other_school)

        get_with_auth(api_v1_teachers_path, admin_user)
        json_response = JSON.parse(response.body)
        expect(json_response["teachers"].map { |t| t["id"] }).not_to include(
          other_teacher.id
        )
      end

      it "returns error if admin user does not own the school" do
        get_with_auth(api_v1_teachers_path, another_admin)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "teacher signed in" do
      let!(:teacher) { create(:user, school: school, role: :teacher) }

      it "returns Forbidden response (403)" do
        get_with_auth(api_v1_teachers_path, teacher)
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include("講師はこの操作を行うことができません")
      end
    end

    context "unauthenticated user" do
      it "returns  an unauthorized response (401)" do
        get api_v1_teachers_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /destroy" do
    let!(:school) { create(:school) }
    let(:teacher) { create(:user, school: school) }
    let(:user) { create(:user, school: school) }

    context "admin signed in" do
      before { user.role = :admin }
      it "deletes a teacher and returns no content (204)" do
        teacher.role = :teacher
        delete_with_auth(api_v1_teacher_path(teacher), user)
        expect(response).to have_http_status(:no_content)
        expect(User.exists?(teacher.id)).to be_falsey
      end
    end
    context "teacher signed in" do
      before { user.role = :teacher }
      it "returns Forbidden response (403)" do
        delete_with_auth(api_v1_teacher_path(teacher), user)
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include(
          I18n.t("application.errors.teacher_unable_operate")
        )
      end
    end
    context "unauthenticated user" do
      it "returns an unauthorized response (401)" do
        delete api_v1_teacher_path(teacher)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
