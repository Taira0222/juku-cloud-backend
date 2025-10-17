class RemoveSchoolCodeFromSchools < ActiveRecord::Migration[8.0]
  def change
    remove_column :schools, :school_code, :string
  end
end
