class CreateStudentTraits < ActiveRecord::Migration[8.0]
  def change
    create_table :student_traits do |t|
      t.references :student, null: false, foreign_key: true
      t.integer :category
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
