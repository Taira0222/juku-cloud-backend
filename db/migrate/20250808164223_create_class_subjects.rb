class CreateClassSubjects < ActiveRecord::Migration[8.0]
  def change
    create_table :class_subjects do |t|
      t.integer :name, null: false

      t.timestamps
    end
  end
end
