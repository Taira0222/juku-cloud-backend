class CreateStudents < ActiveRecord::Migration[8.0]
  def change
    create_table :students do |t|
      t.references :school, null: false, foreign_key: true
      t.string :student_code, null: false
      t.string :name, null: false
      t.integer :status, default: 0, null: false
      t.date :joined_on
      t.date :left_on
      t.integer :school_stage, null: false
      t.integer :grade, null: false
      t.string :desired_school

      t.timestamps
    end
    add_index :students, :student_code, unique: true
  end
end
