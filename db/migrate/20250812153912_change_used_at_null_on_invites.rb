class ChangeUsedAtNullOnInvites < ActiveRecord::Migration[8.0]
  def change
    change_column_null :invites, :used_at, true
  end
end
