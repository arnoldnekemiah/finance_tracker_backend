class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories, id: :uuid do |t|
      t.references :user,               type: :uuid, null: false, foreign_key: true
      t.string     :name,               null: false
      t.string     :icon,               default: '📁'
      t.string     :color,              default: '#000000'
      t.string     :transaction_type,   null: false  # income, expense
      t.uuid       :parent_category_id
      t.timestamps
    end

    add_index :categories, :parent_category_id
    add_foreign_key :categories, :categories, column: :parent_category_id
  end
end
