module Invites
  class TokenGenerateError < StandardError
  end

  class TokenGenerate
    def self.call(school, role: :teacher, expires_at: nil, max_uses: 1)
      raw_token = SecureRandom.urlsafe_base64(32)
      digest = Invite.digest(raw_token)

      Invite.create!(
        token_digest: digest,
        school: school,
        role: role,
        expires_at: expires_at || 7.days.from_now,
        max_uses: max_uses
      )
      { raw_token: raw_token }
    rescue ActiveRecord::RecordInvalid
      # 発行失敗のみドメイン例外にラップ（controllerで422にする）
      raise TokenGenerateError, I18n.t("invites.errors.generate_token_failed")
    end
  end
end
