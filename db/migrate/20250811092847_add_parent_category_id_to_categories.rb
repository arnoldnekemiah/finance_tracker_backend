class AddParentCategoryIdToCategories < ActiveRecord::Migration[7.1]
  def change
    add_column :categories, :parent_category_id, :integer
    add_foreign_key :categories, :categories, column: :parent_category_id
    add_index :categories, :parent_category_id
  end
end
