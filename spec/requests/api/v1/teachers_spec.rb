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

      expect(json).to include(:current_user, :teachers)
      current_user = json[:current_user]
      teachers = json[:teachers]
      teacher1 = teachers[0]
      teacher2 = teachers[1]

      expect(current_user).not_to be_an(Array)
      expect(teachers).to be_an(Array)
      expect(teachers.length).to eq(2)

      # current_user, teachers の中身を確認
      [ current_user, teacher1, teacher2 ].each do |user|
        expect(user).to include(
          :id,
          :provider,
          :uid,
          :allow_password_change,
          :name,
          :role,
          :email,
          :created_at,
          :updated_at,
          :school_id,
          :employment_status,
          :current_sign_in_at
        )
        expect(user[:class_subjects]).to all(include(:id, :name))
        expect(user[:available_days]).to all(include(:id, :name))
        expect(user[:students]).to all(
          include(:id, :name, :status, :school_stage, :grade)
        )
      end
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

    it "fails to destroy a teacher and returns 422 unprocessable_content" do
      # Teachers::Validator が呼ばれたらteacher を返す
      allow(Teachers::Validator).to receive(:call).with(
        id: teacher.id.to_s
      ).and_return(teacher)
      # 帰ってきた teacher の destroy! が呼ばれたら例外を発生させる
      allow(teacher).to receive(:destroy!).and_raise(
        ActiveRecord::RecordNotDestroyed
      )

      delete_with_auth(api_v1_teacher_path(teacher), user)
      expect(response).to have_http_status(:unprocessable_content)
      errors = json[:errors]
      expect(errors).to be_an(Array)
      expect(errors.length).to eq(1)
      expect(errors.first[:code]).to eq("RECORD_NOT_DESTROYED")
      expect(errors.first[:field]).to eq("base")
      expect(errors.first[:message]).to eq(
        I18n.t("application.errors.record_not_destroyed")
      )
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
      expect(json[:teacher_id]).to eq(teacher.id)
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
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include(
        I18n.t("teachers.errors.invalid_argument")
      )
    end
  end
end
