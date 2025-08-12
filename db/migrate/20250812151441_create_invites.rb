class CreateInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :invites do |t|
      t.references :school, null: false, foreign_key: true
      t.string :token, null: false
      t.integer :role, null: false, default: 0 # 0はteacher
      t.integer :max_uses, null: false, default: 1
      t.integer :uses_count, null: false, default: 0
      t.datetime :expires_at, null: false
      t.datetime :used_at, null: false

      t.timestamps
    end
    add_index :invites, :token, unique: true
  end
end
