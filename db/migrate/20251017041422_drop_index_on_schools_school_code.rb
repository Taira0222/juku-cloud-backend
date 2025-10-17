class DropIndexOnSchoolsSchoolCode < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    if index_exists?(:schools, :school_code)
      remove_index :schools, :school_code, algorithm: :concurrently
    end
  end

  def down
    unless index_exists?(:schools, :school_code)
      add_index :schools, :school_code, unique: true, algorithm: :concurrently
    end
  end
end
