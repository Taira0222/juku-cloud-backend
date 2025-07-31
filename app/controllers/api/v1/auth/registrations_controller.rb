class Api::V1::Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  prepend_before_action :extract_school_code, only: :create
  before_action :validate_school_code, only: :create

  # POST /api/v1/auth デフォルトのcreateアクションを使用
  def create
    super
  end

  protected
    def build_resource
      super
      @resource.role   = :teacher
      @resource.school = @school
    end
    # 会員登録の際にparams を追加する場合
    def sign_up_params
      params.permit(:name, :email, :password, :password_confirmation)
    end

  private
    # school_code をparamsから抽出
    def extract_school_code
      @school_code = params.delete(:school_code)
    end

    # school_code の検証
    def validate_school_code
      @school = School.find_by(school_code: @school_code)
      return if @school

      @resource = resource_class.new(sign_up_params)
      # school_codeエラー追加前にDeviseの標準バリデーションを実行
      @resource.valid?

      @resource.errors.add(:school_code, I18n.t("activerecord.errors.models.user.attributes.school_code.invalid"))
      render_create_error
    end
end
