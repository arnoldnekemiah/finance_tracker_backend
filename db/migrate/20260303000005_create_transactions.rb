class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.references :user,               null: false, foreign_key: true
      t.decimal    :amount
      t.references :category,           foreign_key: true
      t.string     :transaction_type
      t.datetime   :date
      t.text       :description
      t.string     :recurring_id
      t.string     :payment_method
      t.references :account,            foreign_key: true
      t.string     :original_currency,  default: "USD"
      t.integer    :original_amount_cents
      t.decimal    :exchange_rate,       precision: 10, scale: 6
      t.integer    :from_account_id
      t.integer    :to_account_id
      t.timestamps
    end

    add_index :transactions, :date
    add_index :transactions, :original_currency
    add_index :transactions, :from_account_id
    add_index :transactions, :to_account_id
    add_foreign_key :transactions, :accounts, column: :from_account_id
    add_foreign_key :transactions, :accounts, column: :to_account_id
  end
end
