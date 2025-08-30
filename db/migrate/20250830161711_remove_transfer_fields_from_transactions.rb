class RemoveTransferFieldsFromTransactions < ActiveRecord::Migration[7.1]
  def up
    # Remove foreign key constraints first if they exist
    if foreign_key_exists?(:transactions, :accounts, column: :from_account_id)
      remove_foreign_key :transactions, column: :from_account_id
    end
    
    if foreign_key_exists?(:transactions, :accounts, column: :to_account_id)
      remove_foreign_key :transactions, column: :to_account_id
    end
    
    # Remove the columns
    remove_column :transactions, :from_account_id, :integer
    remove_column :transactions, :to_account_id, :integer
  end

  def down
    # Add the columns back first
    add_column :transactions, :from_account_id, :integer
    add_column :transactions, :to_account_id, :integer
    
    # Add foreign key constraints
    add_foreign_key :transactions, :accounts, column: :from_account_id
    add_foreign_key :transactions, :accounts, column: :to_account_id
  end
end
