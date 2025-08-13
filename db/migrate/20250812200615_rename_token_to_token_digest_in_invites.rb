class RenameTokenToTokenDigestInInvites < ActiveRecord::Migration[8.0]
  def change
    rename_column :invites, :token, :token_digest
  end
end
