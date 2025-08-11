class AddFromAccountAndToAccountToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :transactions, :from_account_id, :integer
    add_column :transactions, :to_account_id, :integer
    
    add_foreign_key :transactions, :accounts, column: :from_account_id
    add_foreign_key :transactions, :accounts, column: :to_account_id
    add_index :transactions, :from_account_id
    add_index :transactions, :to_account_id
  end
end
