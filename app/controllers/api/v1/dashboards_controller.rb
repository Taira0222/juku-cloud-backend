class Api::V1::DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!
  before_action :ensure_student_access!

  # GET /api/v1/dashboards/:id
  def show
    student = Dashboards::ShowQuery.call(school: @school, id: params[:id])
    render json: Dashboards::ShowResource.new(student).serializable_hash,
           status: :ok
  end
end
