class Api::V1::StudentTraitsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!
  before_action :ensure_student_access!
  before_action :require_admin_role!, only: %i[create update destroy]

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

  # POST /api/v1/student_traits
  def create
    student_trait = StudentTrait.create!(create_params)
    render json:
             StudentTraits::CreateResource.new(student_trait).serializable_hash,
           status: :created
  end

  # PATCH/PUT /api/v1/student_traits/:id
  def update
    student_trait = StudentTrait.find(update_params[:id])
    student_trait.update!(update_params.except(:id))
    render json:
             StudentTraits::UpdateResource.new(student_trait).serializable_hash,
           status: :ok
  end

  # DELETE /api/v1/student_traits/:id
  def destroy
    student_trait = StudentTrait.find(params[:id])
    student_trait.destroy!
    head :no_content
  end

  private

  def index_params
    params.permit(:student_id, :searchKeyword, :sortBy, :page, :perPage)
  end

  def base_params
    %i[student_id title description category]
  end

  def create_params
    params.permit(*base_params)
  end

  def update_params
    params.permit(:id, *base_params)
  end
end
