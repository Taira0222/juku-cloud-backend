class CreateLessonNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :lesson_notes do |t|
      t.references :student_class_subject,
                   null: false,
                   foreign_key: {
                     to_table: :student_class_subjects
                   }
      t.string :title, null: false
      t.text :description

      t.timestamps
    end
  end
end
