class AddNoteTypeToLessonNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :lesson_notes, :note_type, :integer, null: false
    # タイプごとにフィルターをかける可能性があるため、インデックスを追加
    add_index :lesson_notes, :note_type
  end
end
