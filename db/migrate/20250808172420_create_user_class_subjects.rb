class CreateUserClassSubjects < ActiveRecord::Migration[8.0]
  def change
    create_table :user_class_subjects do |t|
      t.references :user, null: false, foreign_key: true
      t.references :class_subject, null: false, foreign_key: true

      t.timestamps
    end
    add_index :user_class_subjects, [ :user_id, :class_subject_id ], unique: true
  end
end
