require "rails_helper"

RSpec.describe "Api::V1::Teachers", type: :request do
  describe "GET /index" do
    let!(:user) { create(:user, role: :admin) }
    let!(:school) { create(:school, owner: user) }
    let!(:teacher1) { create(:user, school: school) }
    let!(:teacher2) { create(:user, school: school) }

    it "returns a list of teachers for the specified school" do
      get_with_auth(api_v1_teachers_path, user)
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response).to have_key("current_user")
      expect(json_response).to have_key("teachers")
      expect(json_response["teachers"].length).to eq(2)
    end
  end

  describe "DELETE /destroy" do
    let!(:school) { create(:school) }
    let!(:teacher) { create(:user, school: school) }
    let!(:user) { create(:user, role: :admin) }

    it "deletes a teacher and returns no content (204)" do
      delete_with_auth(api_v1_teacher_path(teacher), user)
      expect(response).to have_http_status(:no_content)
      expect(User.exists?(teacher.id)).to be_falsey
    end

    it "returns validation errors if user does not exist" do
      delete_with_auth(api_v1_teacher_path("invalid_id"), user)
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include(I18n.t("teachers.errors.not_found"))
    end

    it "does not destroy a teacher and returns 422 unprocessable_content" do
      # destroy アクションが呼ばれたらfalse を返す
      allow(teacher).to receive(:destroy).and_return(false)
      # Teachers::Validator のteacher を差し替える必要がある
      allow(Teachers::Validator).to receive(:call).with(
        id: teacher.id.to_s
      ).and_return(double(ok?: true, teacher: teacher, error: nil, status: nil))

      delete_with_auth(api_v1_teacher_path(teacher), user)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("teachers.errors.delete.failure"))
    end
  end

  describe "PATCH /update" do
    let!(:school) { create(:school) }
    let!(:user) { create(:user, role: :admin) }
    let!(:teacher) { create(:user, id: 1, name: "Old Name", school: school) }

    it "updates a teacher and returns the teacher id" do
      patch_with_auth(
        api_v1_teacher_path(teacher),
        user,
        params: {
          id: "1",
          name: "New Name"
        }
      )
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response["teacher_id"]).to eq(teacher.id)
      expect(teacher.reload.name).to eq("New Name")
    end

    it "returns an error if the update fails" do
      patch_with_auth(
        api_v1_teacher_path(teacher),
        user,
        params: {
          id: "1",
          name: "New Name",
          employment_status: "invalid_status"
        }
      )
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(
        I18n.t("teachers.errors.invalid_argument")
      )
    end
  end
end
