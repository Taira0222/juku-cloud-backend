class Api::V1::Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  # 例外をまとめて処理
  rescue_from Invites::InvalidInviteError, with: :render_invalid_invite

  # POST /api/v1/auth デフォルトのcreateアクションを使用
  def create
    # Invite::InvalidInviteError が発生するかも
    extract_token!

    @invite = Invites::Validator.call(@raw_token)
    @school = @invite.school

    super
    # レスポンス完了、成功、DBに保存できた場合
    if performed? && response.status.in?([ 200, 201 ]) && @resource&.persisted?
      @invite.consume!
    end
  end

  protected

  def build_resource
    super
    @resource.role = :teacher
    @resource.school = @school
  end
  # 会員登録の際にparams を追加する場合
  def sign_up_params
    params.permit(:name, :email, :password, :password_confirmation)
  end

  private

  # token をparamsから抽出
  def extract_token!
    @raw_token = params.delete(:token)
    # token が存在しない場合は例外を発生させる
    unless @raw_token.present?
      raise Invites::InvalidInviteError, I18n.t("invites.errors.invalid")
    end
  end

  # Invites::InvalidInviteError が発生した際に呼ばれるメソッド
  def render_invalid_invite(e)
    @resource = resource_class.new(sign_up_params)
    @resource.valid?
    @resource.errors.add(:token, e.message)
    render_create_error
  end
end
