class RemoveStartedOnAndTeachingStatusFromTeachingAssignments < ActiveRecord::Migration[8.0]
  def change
    remove_column :teaching_assignments, :started_on, :date
    remove_column :teaching_assignments, :teaching_status, :boolean
  end
end
