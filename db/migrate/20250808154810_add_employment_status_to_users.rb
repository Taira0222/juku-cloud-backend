class AddEmploymentStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :employment_status, :integer, default: 0, null: false
  end
end
