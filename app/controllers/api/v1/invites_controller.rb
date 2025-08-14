class Api::V1::InvitesController < ApplicationController
  before_action :authenticate_user!, only: :create
  before_action :require_admin_role!, only: :create
  before_action :set_school!, only: :create

  # GET /api/v1/invites/:token
  def show
    # 例外の場合にはinvite はセットされず、rescue へ飛ぶ
    invite = Invites::Validator.call(params[:token])
    render json: { school_name: invite.school.name }
  rescue Invites::InvalidInviteError => e
    # 404 エラー
    render json: { message: e.message }, status: :not_found
  rescue StandardError => e
    # 予期せぬエラー 500
    render json: {
             message: I18n.t("invites.errors.unexpected")
           },
           status: :internal_server_error
  end

  # POST /api/v1/invites
  def create
    result = Invites::TokenGenerate.call(@school)
    render json: { token: result[:raw_token] }, status: :created
  rescue Invites::TokenGenerateError => e
    # 422 エラー
    render json: { message: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    # 予期せぬエラー 500
    render json: {
             message: I18n.t("invites.errors.unexpected")
           },
           status: :internal_server_error
  end
end
