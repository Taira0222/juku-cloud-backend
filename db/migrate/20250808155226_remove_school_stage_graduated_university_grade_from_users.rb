class RemoveSchoolStageGraduatedUniversityGradeFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :school_stage, :integer
    remove_column :users, :graduated_university, :string
    remove_column :users, :grade, :integer
  end
end
