require "rails_helper"

RSpec.describe ErrorHandlers, type: :controller do
  controller(ApplicationController) do
    def internal_server_error
      raise StandardError, I18n.t("application.errors.internal_server_error")
    end

    def not_found
      raise ActiveRecord::RecordNotFound, "Record Not Found"
    end

    def forbidden
      raise ForbiddenError, "Forbidden Access"
    end

    def record_not_destroyed
      raise ActiveRecord::RecordNotDestroyed.new(
              I18n.t("application.errors.record_not_destroyed")
            )
    end

    def record_invalid
      record = User.new
      record.validate
      raise ActiveRecord::RecordInvalid.new(record)
    end

    def invalid_foreign_key
      raise ActiveRecord::InvalidForeignKey,
            I18n.t("errors.invalid_foreign_key")
    end

    def record_not_unique
      raise ActiveRecord::RecordNotUnique, I18n.t("errors.record_not_unique")
    end

    def not_null_violation
      raise ActiveRecord::NotNullViolation, I18n.t("errors.not_null_violation")
    end

    def argument_error
      raise ArgumentError, I18n.t("errors.argument_error")
    end
  end

  # 仮想のルーティングを設定し、get で各アクションを呼び出せるようにする
  before do
    routes.draw do
      get "internal_server_error" => "anonymous#internal_server_error"
      get "not_found" => "anonymous#not_found"
      get "forbidden" => "anonymous#forbidden"
      get "record_not_destroyed" => "anonymous#record_not_destroyed"
      get "record_invalid" => "anonymous#record_invalid"
      get "invalid_foreign_key" => "anonymous#invalid_foreign_key"
      get "record_not_unique" => "anonymous#record_not_unique"
      get "not_null_violation" => "anonymous#not_null_violation"
      get "argument_error" => "anonymous#argument_error"
    end
  end

  describe "ErrorHandlers" do
    it "handles StandardError with 500" do
      get :internal_server_error
      expect(response).to have_http_status(:internal_server_error)
      error = json[:errors].first
      expect(error[:code]).to eq "INTERNAL_SERVER_ERROR"
      expect(error[:field]).to eq "base"
      expect(error[:message]).to eq I18n.t(
           "application.errors.internal_server_error"
         )
    end

    it "handles ActiveRecord::RecordNotFound with 404" do
      get :not_found
      expect(response).to have_http_status(:not_found)
      error = json[:errors].first
      expect(error[:code]).to eq "NOT_FOUND"
      expect(error[:field]).to eq "base"
      expect(error[:message]).to eq "Record Not Found"
    end

    it "handles ForbiddenError with 403" do
      get :forbidden
      expect(response).to have_http_status(:forbidden)
      error = json[:errors].first
      expect(error[:code]).to eq "FORBIDDEN"
      expect(error[:field]).to eq "base"
      expect(error[:message]).to eq "Forbidden Access"
    end

    it "handles ActiveRecord::RecordNotDestroyed with 422" do
      get :record_not_destroyed
      expect(response).to have_http_status(:unprocessable_content)
      error = json[:errors].first
      expect(error[:code]).to eq "RECORD_NOT_DESTROYED"
      expect(error[:field]).to eq "base"
      expect(error[:message]).to eq I18n.t(
           "application.errors.record_not_destroyed"
         )
    end

    it "handles ActiveRecord::RecordInvalid with 422" do
      get :record_invalid
      expect(response).to have_http_status(:unprocessable_content)
      error = json[:errors].first
      expect(error[:code]).to eq "BLANK"
      expect(error[:field]).to eq "password"
      expect(error[:message]).to eq "パスワードを入力してください"
    end

    it "handles ActiveRecord::InvalidForeignKey with 422" do
      get :invalid_foreign_key
      expect(response).to have_http_status(:unprocessable_content)
      error = json[:errors].first
      expect(error[:code]).to eq "INVALID_FOREIGN_KEY"
      expect(error[:field]).to eq "base"
      expect(error[:message]).to eq I18n.t("errors.invalid_foreign_key")
    end

    it "handles ActiveRecord::RecordNotUnique with 422" do
      get :record_not_unique
      expect(response).to have_http_status(:unprocessable_content)
      error = json[:errors].first
      expect(error[:code]).to eq "NOT_UNIQUE"
      expect(error[:field]).to eq "base"
      expect(error[:message]).to eq I18n.t("errors.not_unique")
    end

    it "handles ActiveRecord::NotNullViolation with 422" do
      get :not_null_violation
      expect(response).to have_http_status(:unprocessable_content)
      error = json[:errors].first
      expect(error[:code]).to eq "NOT_NULL_VIOLATION"
      expect(error[:field]).to eq "base"
      expect(error[:message]).to eq I18n.t("errors.not_null_violation")
    end

    it "handles ArgumentError with 400" do
      get :argument_error
      expect(response).to have_http_status(:bad_request)
      error = json[:errors].first
      expect(error[:code]).to eq "INVALID_ARGUMENT"
      expect(error[:field]).to eq "base"
      expect(error[:message]).to eq I18n.t("errors.argument_error")
    end
  end
end
