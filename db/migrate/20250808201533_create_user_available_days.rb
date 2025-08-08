class CreateUserAvailableDays < ActiveRecord::Migration[8.0]
  def change
    create_table :user_available_days do |t|
      t.references :user, null: false, foreign_key: true
      t.references :available_day, null: false, foreign_key: true

      t.timestamps
    end
    add_index :user_available_days, [ :user_id, :available_day_id ], unique: true
  end
end
