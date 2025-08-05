class Api::V1::TeachersController < ApplicationController
  before_action :authenticate_user!

  def index
    begin
      @current_user = current_user
      @school = School.find_by(owner_id: @current_user.id)
      if @school.nil?
        render json: { error: "学校が見つかりません" }, status: :not_found
        return
      end
      @teachers = User.where(school: @school)

      render json: {
        current_user: @current_user,
        teachers: @teachers
      }, status: :ok
    rescue StandardError => e
      render json: { error: "予期しないエラーが発生しました: #{e.message}" }, status: :internal_server_error
    end
  end
end
