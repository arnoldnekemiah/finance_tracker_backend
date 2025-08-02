class RefactorBudgets < ActiveRecord::Migration[7.1]
  def change
    remove_column :budgets, :category, :string
    add_reference :budgets, :category, foreign_key: true
    add_column :budgets, :period, :string
  end
end
