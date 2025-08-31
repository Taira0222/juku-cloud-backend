class Api::V1::StudentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!

  def index
    students =
      Students::IndexQuery.call(
        school: @school,
        page: index_params[:page],
        per_page: index_params[:perPage]
      )
    render json: Students::IndexPresenter.new(students).as_json
  end

  private

  def index_params
    params.permit(:page, :perPage)
  end
end
