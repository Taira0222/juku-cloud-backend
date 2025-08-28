class RemoveStudentCodeAndLeftOnFromStudents < ActiveRecord::Migration[8.0]
  def change
    remove_column :students, :student_code, :string
    remove_column :students, :left_on, :date
  end
end
