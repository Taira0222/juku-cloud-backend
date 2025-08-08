class CreateStudentAvailableDays < ActiveRecord::Migration[8.0]
  def change
    create_table :student_available_days do |t|
      t.references :student, null: false, foreign_key: true
      t.references :available_day, null: false, foreign_key: true

      t.timestamps
    end
    add_index :student_available_days, [ :student_id, :available_day_id ], unique: true
  end
end
