module ResultRenderable
  extend ActiveSupport::Concern

  def render_result(result, success_status: :ok)
    if result.ok?
      # ブロックで渡された場合、それに従う
      payload = block_given? ? yield(result.value) : result.value
      render json: payload, status: success_status
    else
      render json: {
               errors: Array(result.errors)
             },
             status: :unprocessable_content
    end
  end
end
