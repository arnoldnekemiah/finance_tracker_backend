class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount
      t.references :category, foreign_key: true
      t.string :transaction_type
      t.datetime :date
      t.text :description
      t.string :recurring_id
      t.string :payment_method
      t.references :account, foreign_key: true

      t.timestamps
    end
  end
end
