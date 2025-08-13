class Api::V1::TeachersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_role!
  before_action :set_school!

  def index
    result = Teachers::IndexQuery.call(current_user, school: @school)
    render json: Teachers::IndexPresenter.new(result).as_json, status: :ok
  end
end
