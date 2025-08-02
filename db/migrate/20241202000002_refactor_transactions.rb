class RefactorTransactions < ActiveRecord::Migration[7.1]
  def change
    remove_column :transactions, :category, :string
    add_reference :transactions, :category, foreign_key: true
    add_column :transactions, :payment_method, :string
  end
end
