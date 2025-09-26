class AddMetaToLessonNotes < ActiveRecord::Migration[8.0]
  def change
    change_table :lesson_notes, bulk: true do |t|
      # FKはNULL許可 + 親削除時NULL化
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
      t.date :expire_date, null: false
    end
    # expire_date で検索するので index を貼る
    add_index :lesson_notes, :expire_date
  end
end
