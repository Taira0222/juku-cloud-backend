class Api::V1::StudentTraitsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!
  before_action :ensure_student_access!

  # GET /api/v1/student_traits
  def index
    student_traits =
      StudentTraits::IndexQuery.call(
        school: @school,
        index_params: index_params
      )
    render json: {
             student_traits:
               StudentTraits::IndexResource.new(
                 student_traits
               ).serializable_hash,
             meta: {
               total_pages: student_traits.total_pages,
               total_count: student_traits.total_count,
               current_page: student_traits.current_page,
               per_page: student_traits.limit_value
             }
           },
           status: :ok
  end

  private

  def index_params
    params.permit(:student_id, :searchKeyword, :sortBy, :page, :perPage)
  end
end
