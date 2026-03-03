class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string     :name,             null: false
      t.string     :icon
      t.string     :color
      t.string     :transaction_type, null: false
      t.references :user,             null: false, foreign_key: true
      t.integer    :parent_category_id
      t.timestamps
    end

    add_index :categories, :parent_category_id
    add_foreign_key :categories, :categories, column: :parent_category_id
  end
end
