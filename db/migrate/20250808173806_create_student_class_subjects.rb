class CreateStudentClassSubjects < ActiveRecord::Migration[8.0]
  def change
    create_table :student_class_subjects do |t|
      t.references :student, null: false, foreign_key: true
      t.references :class_subject, null: false, foreign_key: true

      t.timestamps
    end
    add_index :student_class_subjects, [:student_id, :class_subject_id], unique: true
  end
end
