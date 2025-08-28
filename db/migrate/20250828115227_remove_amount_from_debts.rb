class RemoveAmountFromDebts < ActiveRecord::Migration[7.1]
  def change
    remove_column :debts, :amount, :decimal
  end
end
