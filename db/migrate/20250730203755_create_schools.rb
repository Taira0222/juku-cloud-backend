class CreateSchools < ActiveRecord::Migration[8.0]
  def change
    create_table :schools do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users } # userのadmin をownerとする
      t.string :name, null: false # null 禁止
      t.string :school_code, null: false # null 禁止

      t.timestamps
    end
    # school_codeにユニークインデックスを追加
    add_index :schools, :school_code, unique: true
  end
end
