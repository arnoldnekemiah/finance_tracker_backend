class AddCentsToBudgets < ActiveRecord::Migration[7.1]
  def change
    add_column :budgets, :limit_cents, :integer, default: 0, null: false
    add_column :budgets, :spent_cents, :integer, default: 0, null: false
    remove_column :budgets, :limit, :decimal
    remove_column :budgets, :spent, :decimal
  end
end
