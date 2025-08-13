class Invites::Validator
  def self.call(token)
    invite = Invite.find_by_raw_token!(token)
    # 有効なinvite でなければ例外を発生させる
    raise ActiveRecord::RecordNotFound unless !invite.valid_invite?
    # 該当する invite を返却する
    invite
  rescue ActiveRecord::RecordNotFound
    raise InvalidInviteError, I18n.t("invites.errors.invalid")
  end

  # 招待リンクが無効な場合のエラー
  class InvalidInviteError < StandardError
  end
end
