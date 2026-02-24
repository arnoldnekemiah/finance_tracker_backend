class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions, id: :uuid do |t|
      t.references :user,              type: :uuid, null: false, foreign_key: true
      t.decimal    :amount,            precision: 15, scale: 2, null: false
      t.decimal    :original_amount,   precision: 15, scale: 2, null: false
      t.string     :original_currency, default: 'USD'
      t.string     :transaction_type,  null: false  # income, expense, transfer
      t.references :category,          type: :uuid, foreign_key: true
      t.string     :category_name
      t.datetime   :date,              null: false
      t.text       :description
      t.uuid       :from_account_id
      t.uuid       :to_account_id
      t.string     :payment_method
      t.timestamps
    end

    add_index :transactions, :date
    add_index :transactions, :from_account_id
    add_index :transactions, :to_account_id
    add_foreign_key :transactions, :accounts, column: :from_account_id
    add_foreign_key :transactions, :accounts, column: :to_account_id
  end
end
