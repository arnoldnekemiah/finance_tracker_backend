class RemoveAmountFromTransactions < ActiveRecord::Migration[7.1]
  def change
    remove_column :transactions, :amount, :decimal
    remove_column :transactions, :exchange_rate, :decimal
  end
end
