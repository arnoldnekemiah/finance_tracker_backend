class AddCurrencySupportToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :preferred_currency, :string, default: 'USD', null: false
    add_column :users, :timezone, :string, default: 'UTC'
    add_index :users, :preferred_currency
  end
end
