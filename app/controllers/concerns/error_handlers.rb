module ErrorHandlers
  extend ActiveSupport::Concern

  included do
    # 500
    rescue_from StandardError do |e|
      raise e if Rails.env.development?

      Rails.logger.error("[500] #{e.class}: #{e.message}")
      Rails.logger.error(Array(e.backtrace).join("\n"))

      render_error!(
        code: "INTERNAL_SERVER_ERROR",
        field: "base",
        message: I18n.t("application.errors.internal_server_error"),
        status: :internal_server_error
      )
    end
    # 404
    rescue_from ActiveRecord::RecordNotFound do |e|
      render_error!(
        code: "NOT_FOUND",
        field: "base",
        message: e.message || I18n.t("application.errors.not_found"),
        status: :not_found
      )
    end
    # 403
    rescue_from ForbiddenError do |e|
      render_error!(
        code: "FORBIDDEN",
        field: "base",
        message: (e.message || I18n.t("application.errors.forbidden")),
        status: :forbidden
      )
    end

    # destroy! 失敗時の例外
    rescue_from ActiveRecord::RecordNotDestroyed do |e|
      render_error!(
        code: "RECORD_NOT_DESTROYED",
        field: "base",
        message: (I18n.t("application.errors.record_not_destroyed")),
        status: :unprocessable_content
      )
    end

    # 422 バリデーションエラー
    rescue_from ActiveRecord::RecordInvalid do |e|
      render_model_errors!(
        e.record,
        status: :unprocessable_content,
        default_code: "VALIDATION_FAILED"
      )
    end

    # 422 DB 制約
    rescue_from ActiveRecord::InvalidForeignKey do |e|
      render_error!(
        code: "INVALID_FOREIGN_KEY",
        field: "base",
        message: I18n.t("activerecord.errors.invalid_foreign_key"),
        status: :unprocessable_content
      )
    end

    rescue_from ActiveRecord::RecordNotUnique do |e|
      render_error!(
        code: "NOT_UNIQUE",
        field: "base",
        message: I18n.t("activerecord.errors.not_unique"),
        status: :unprocessable_content
      )
    end

    rescue_from ActiveRecord::NotNullViolation do |e|
      render_error!(
        code: "NOT_NULL_VIOLATION",
        field: "base",
        message: I18n.t("activerecord.errors.not_null_violation"),
        status: :unprocessable_content
      )
    end
    # 400
    rescue_from ArgumentError do |e|
      render_error!(
        code: "INVALID_ARGUMENT",
        field: "base",
        message: e.message || I18n.t("activerecord.errors.argument_error"),
        status: :bad_request
      )
    end
  end
end
