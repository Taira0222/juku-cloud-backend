class UpdateTeachingAssignments < ActiveRecord::Migration[8.0]
  def change
    remove_column :teaching_assignments, :student_id, :bigint
    add_reference :teaching_assignments,
                  :student_class_subject,
                  null: false,
                  foreign_key: {
                    to_table: :student_class_subjects
                  }

    add_index :teaching_assignments,
              %i[student_class_subject_id user_id],
              unique: true,
              name: "index_teaching_assignments_on_scs_and_user"
  end
end
