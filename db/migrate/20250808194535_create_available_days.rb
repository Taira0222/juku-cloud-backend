class CreateAvailableDays < ActiveRecord::Migration[8.0]
  def change
    create_table :available_days do |t|
      t.integer :name, null: false

      t.timestamps
    end
  end
end
