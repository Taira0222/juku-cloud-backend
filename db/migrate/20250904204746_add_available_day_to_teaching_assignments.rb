class AddAvailableDayToTeachingAssignments < ActiveRecord::Migration[8.0]
  def change
    add_reference :teaching_assignments,
                  :available_day,
                  null: false,
                  foreign_key: true
    add_index :teaching_assignments,
              %i[user_id student_class_subject_id available_day_id],
              unique: true,
              name: "idx_assignments_user_subject_day_unique"
  end
end
