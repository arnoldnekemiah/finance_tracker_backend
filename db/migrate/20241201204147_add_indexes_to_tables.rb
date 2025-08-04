class AddIndexesToTables < ActiveRecord::Migration[7.1]
  def change
    add_index :transactions, :date
  end
end
