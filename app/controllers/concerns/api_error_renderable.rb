module ApiErrorRenderable
  extend ActiveSupport::Concern

  private

  # ActiveRecord::Errors を (code, field, message) に正規化
  def render_model_errors!(
    resource,
    status: :unprocessable_content,
    default_code: "VALIDATION_FAILED"
  )
    errors =
      resource.errors.map do |error|
        {
          code: (error.type || default_code).to_s.upcase,
          field: error.attribute.to_s,
          message: resource.errors.full_message(error.attribute, error.message)
        }
      end
    render json: { errors: errors }, status: status
  end

  def render_error!(
    code:,
    message:,
    field: "base",
    status: :unprocessable_content
  )
    render json: {
             errors: [ { code: code, field: field, message: message } ]
           },
           status: status
  end
end
