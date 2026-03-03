class CreateBudgets < ActiveRecord::Migration[7.1]
  def change
    create_table :budgets do |t|
      t.references :user,               null: false, foreign_key: true
      t.decimal    :limit
      t.decimal    :spent
      t.datetime   :start_date
      t.datetime   :end_date
      t.references :category,           foreign_key: true
      t.string     :period
      t.string     :original_currency,  default: "USD"
      t.integer    :original_amount_cents
      t.decimal    :exchange_rate,       precision: 10, scale: 6
      t.timestamps
    end

    add_index :budgets, :original_currency
  end
end
