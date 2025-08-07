class AddCurrencyToFinancialRecords < ActiveRecord::Migration[7.1]
  def change
    # Store original currency and amount for transactions
    add_column :transactions, :original_currency, :string, default: 'USD'
    add_column :transactions, :original_amount_cents, :integer
    add_column :transactions, :exchange_rate, :decimal, precision: 10, scale: 6
    
    # Store original currency and amount for budgets
    add_column :budgets, :original_currency, :string, default: 'USD'
    add_column :budgets, :original_amount_cents, :integer
    add_column :budgets, :exchange_rate, :decimal, precision: 10, scale: 6
    
    # Store original currency and amount for debts
    add_column :debts, :original_currency, :string, default: 'USD'
    add_column :debts, :original_amount_cents, :integer
    
    # Store original currency and amount for saving goals
    add_column :saving_goals, :original_currency, :string, default: 'USD'
    add_column :saving_goals, :original_amount_cents, :integer
    
    # Store original currency and amount for accounts
    add_column :accounts, :original_currency, :string, default: 'USD'
    add_column :accounts, :original_amount_cents, :integer
    
    # Add indexes for performance
    add_index :transactions, :original_currency
    add_index :budgets, :original_currency
    add_index :debts, :original_currency
    add_index :saving_goals, :original_currency
    add_index :accounts, :original_currency
  end
end
