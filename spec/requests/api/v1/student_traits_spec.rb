require "rails_helper"

RSpec.describe "Api::V1::StudentTraits", type: :request do
  let!(:admin_user) { create(:admin_user) }
  let!(:teacher) { create(:user, school: school) }
  let!(:other_admin_user) { create(:admin_user) }
  let!(:school) { create(:school, owner: admin_user) }
  let!(:other_school) { create(:school, owner: other_admin_user) }
  let!(:student) { create(:student, school: school) }
  let!(:student2) { create(:student, school: school) }
  let!(:other_student) { create(:student, school: other_school) }

  describe "GET /index" do
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
    let!(:student_traits) { create_list(:student_trait, 5, student: student) }

    context "an authenticated admin user" do
      let(:index_params) { { student_id: student.id, page: 1, perPage: 10 } }
      it "returns a successful response with student traits" do
        get_with_auth(
          api_v1_student_traits_path,
          admin_user,
          params: index_params
        )
        expect(response).to have_http_status(:success)
        expect(json[:student_traits].size).to eq(5)
        expect(json[:meta][:total_pages]).to eq(1)
        expect(json[:meta][:total_count]).to eq(5)
        expect(json[:meta][:current_page]).to eq(1)
        expect(json[:meta][:per_page]).to eq(10)
      end

      it "returns 404 when the student does not exist" do
        get_with_auth(
          api_v1_student_traits_path,
          admin_user,
          params: {
            student_id: 0
          }
        )
        expect(response).to have_http_status(:not_found)
      end
    end

    context "an authenticated teacher" do
      let(:index_params) { { student_id: student.id, page: 1, perPage: 10 } }
      it "returns a successful response with student traits" do
        get_with_auth(api_v1_student_traits_path, teacher, params: index_params)
        expect(response).to have_http_status(:success)
        expect(json[:student_traits].size).to eq(5)
        expect(json[:meta][:total_pages]).to eq(1)
        expect(json[:meta][:total_count]).to eq(5)
        expect(json[:meta][:current_page]).to eq(1)
        expect(json[:meta][:per_page]).to eq(10)
      end

      it "returns 403 when accessing a student from another school" do
        get_with_auth(
          api_v1_student_traits_path,
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
          api_v1_student_traits_path,
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
        get api_v1_student_traits_path, params: { student_id: student.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  describe "POST /create" do
    let(:create_params) do
      {
        student_id: student.id,
        title: "明るい",
        description: "いつも明るく元気",
        category: "good"
      }
    end
    context "an authenticated admin user" do
      context "with valid parameters" do
        it "creates a new StudentTrait and returns 201 Created" do
          expect {
            post_with_auth(
              api_v1_student_traits_path,
              admin_user,
              params: create_params
            )
          }.to change(StudentTrait, :count).by(1)
          expect(response).to have_http_status(:created)
          expect(json[:title]).to eq("明るい")
          expect(json[:description]).to eq("いつも明るく元気")
          expect(json[:category]).to eq("good")
        end
      end

      context "with invalid parameters" do
        it "returns 422 Unprocessable Content" do
          create_params[:title] = ""
          post_with_auth(
            api_v1_student_traits_path,
            admin_user,
            params: create_params
          )
          expect(response).to have_http_status(:unprocessable_content)
        end
        it "returns 400 Bad Request when category is invalid" do
          create_params[:category] = "invalid"
          post_with_auth(
            api_v1_student_traits_path,
            admin_user,
            params: create_params
          )
          expect(response).to have_http_status(:bad_request)
        end
      end
    end
    context "an authenticated teacher" do
      it "returns 403 Forbidden" do
        post_with_auth(
          api_v1_student_traits_path,
          teacher,
          params: create_params
        )
        expect(response).to have_http_status(:forbidden)
      end
    end
    context "an unauthenticated user" do
      it "returns 401 Unauthorized" do
        post api_v1_student_traits_path, params: create_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  describe "PATCH /update" do
    let!(:student_trait) { create(:student_trait, student: student) }
    let(:update_params) do
      {
        id: student_trait.id,
        title: "落ち着きがない",
        description: "授業中に席を立つことが多い",
        category: "careful",
        student_id: student.id
      }
    end
    context "an authenticated admin user" do
      context "with valid parameters" do
        it "updates the StudentTrait and returns 200 OK" do
          patch_with_auth(
            api_v1_student_trait_path(student_trait),
            admin_user,
            params: update_params
          )
          expect(response).to have_http_status(:ok)
          student_trait.reload
          expect(student_trait.title).to eq("落ち着きがない")
          expect(student_trait.description).to eq("授業中に席を立つことが多い")
          expect(student_trait.category).to eq("careful")
        end
      end

      context "with invalid parameters" do
        it "returns 422 Unprocessable Content" do
          update_params[:title] = ""
          patch_with_auth(
            api_v1_student_trait_path(student_trait),
            admin_user,
            params: update_params
          )
          expect(response).to have_http_status(:unprocessable_content)
        end
        it "returns 400 Bad Request when category is invalid" do
          update_params[:category] = "invalid"
          patch_with_auth(
            api_v1_student_trait_path(student_trait),
            admin_user,
            params: update_params
          )
          expect(response).to have_http_status(:bad_request)
        end
      end
    end
    context "an authenticated teacher" do
      it "returns 403 Forbidden" do
        patch_with_auth(
          api_v1_student_trait_path(student_trait),
          teacher,
          params: update_params
        )
        expect(response).to have_http_status(:forbidden)
      end
    end
    context "an unauthenticated user" do
      it "returns 401 Unauthorized" do
        patch api_v1_student_trait_path(student_trait), params: update_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
