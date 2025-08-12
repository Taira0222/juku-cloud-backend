class AddInviteToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :invite, foreign_key: true
  end
end
