class Api::V1::StudentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!

  def index
    students =
      Students::IndexQuery.call(school: @school, index_params: index_params)
    render json: Students::IndexPresenter.new(students).as_json
  end

  private

  def index_params
    params.permit(:searchKeyword, :school_stage, :grade, :page, :perPage)
  end
end
