class CreateTeachingAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :teaching_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.date :started_on
      t.boolean :teaching_status

      t.timestamps
    end
  end
end
