class DeviseTokenAuthCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table(:users) do |t|
      ## Required
      t.string :provider, null: false, default: "email"
      t.string :uid, null: false, default: ""

      ## Database authenticatable
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.boolean  :allow_password_change, default: false

      ## Rememberable
      t.datetime :remember_created_at

      ## User Info
      t.string :name, null: false, default: ""
      t.integer :role, null: false, default: 0
      t.integer :school_stage
      t.integer :grade
      t.string :graduated_university
      t.string :email, null: false, default: ""

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Tokens
      t.json :tokens

      t.timestamps
    end

    add_index :users, :email,                unique: true
    add_index :users, [ :uid, :provider ],     unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
