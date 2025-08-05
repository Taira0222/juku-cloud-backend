class Api::V1::TeachersController < ApplicationController
  before_action :authenticate_user!

  def index
    @current_user = current_user
    @school = School.find_by(owner_id: @current_user.id)
    if @school.nil?
      render json: { error: "学校が見つかりません" }, status: :not_found
      return
    end
    @teachers = User.where(school: @school)
    # current_user も講師を務める可能性があるので含める
    render json: {
      current_user: @current_user,
      teachers: @teachers
    }, status: :ok
  end
end
