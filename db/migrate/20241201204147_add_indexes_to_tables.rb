class AddIndexesToTables < ActiveRecord::Migration[7.1]
  def change
    add_index :transactions, :date
    add_index :transactions, :category
  end
end
