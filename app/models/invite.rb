# == Schema Information
#
# Table name: invites
#
#  id           :bigint           not null, primary key
#  expires_at   :datetime         not null
#  max_uses     :integer          default(1), not null
#  role         :integer          default("teacher"), not null
#  token_digest :string           not null
#  used_at      :datetime
#  uses_count   :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  school_id    :bigint           not null
#
# Indexes
#
#  index_invites_on_school_id     (school_id)
#  index_invites_on_token_digest  (token_digest) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (school_id => schools.id)
#
class Invite < ApplicationRecord
  # school:Invite 1:N
  belongs_to :school
  # Invite:User 1:1
  has_one :user

  enum :role, { teacher: 0, admin: 1 }, suffix: true

  validates :token_digest, presence: true, uniqueness: true
  # role はteacher or admin のみ受け付ける
  validates :role, presence: true, inclusion: { in: roles.keys }
  validates :max_uses, presence: true
  validates :expires_at,
            presence: true,
            comparison: {
              greater_than: -> { Time.current }
            },
            on: :create

  # raw_tokenから digest を検索(例外処理用の!)
  def self.find_by_raw_token!(raw_token)
    digest = digest(raw_token)
    find_by!(token_digest: digest)
  rescue ActiveRecord::RecordNotFound
    raise ActiveRecord::RecordNotFound, I18n.t("invites.errors.invalid")
  end

  # 期限切れチェック
  def expired?
    expires_at.present? && Time.current > expires_at
  end

  # 使用回数上限チェック
  def exhausted?
    max_uses.present? && uses_count >= max_uses
  end

  # 有効性の確認
  def valid_invite?
    !expired? && !exhausted?
  end

  # 消費処理
  def consume!
    update!(
      uses_count: uses_count + 1,
      used_at: (max_uses == 1 ? Time.current : used_at)
    )
  end

  # raw_tokenをdigest に変換
  def self.digest(raw_token)
    secret = Rails.application.secret_key_base
    OpenSSL::HMAC.hexdigest("SHA256", secret, raw_token)
  end
end
