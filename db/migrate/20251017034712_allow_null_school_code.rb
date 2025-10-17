class AllowNullSchoolCode < ActiveRecord::Migration[8.0]
   def up
    change_column_null :schools, :school_code, true
  end
end
