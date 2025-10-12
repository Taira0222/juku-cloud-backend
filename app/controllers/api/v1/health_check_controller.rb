class Api::V1::HealthCheckController < ApplicationController
  # GET /api/v1/health_check
  def show
    render json: { status: "ok" }, status: :ok
  end
end
