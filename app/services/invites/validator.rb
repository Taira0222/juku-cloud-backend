module Invites
  class Validator
    def self.call(token)
      # 該当なしなら ActiveRecord::RecordNotFound を発生させる
      invite = Invite.find_by_raw_token!(token)
      unless invite.valid_invite?
        raise ActiveRecord::RecordNotFound, I18n.t("invites.errors.invalid")
      end
      invite
    end
  end
end
