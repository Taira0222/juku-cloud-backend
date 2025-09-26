class AddMetaToStudentTrait < ActiveRecord::Migration[8.0]
  def change
    change_table :student_traits do |t|
      t.references :created_by,
                   null: true,
                   foreign_key: {
                     to_table: :users,
                     on_delete: :nullify
                   }
      t.references :last_updated_by,
                   null: true,
                   foreign_key: {
                     to_table: :users,
                     on_delete: :nullify
                   }
      # 表示用スナップショット
      t.string :created_by_name, null: false, default: ""
      t.string :last_updated_by_name
    end
  end
end
