class Api::V1::InvitesController < ApplicationController
  before_action :authenticate_user!, only: :create
  before_action :require_admin_role!, only: :create
  before_action :set_school!, only: :create

  # GET /api/v1/invites/:token
  def show
    invite = Invites::Validator.call(params[:token])
    render json: { school_name: invite.school.name }
  end

  # POST /api/v1/invites
  def create
    result = Invites::TokenGenerate.call(@school)

    render json: { token: result }, status: :created
  end
end
