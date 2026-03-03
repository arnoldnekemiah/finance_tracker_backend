class CreateDebts < ActiveRecord::Migration[7.1]
  def change
    create_table :debts do |t|
      t.references :user,               null: false, foreign_key: true
      t.string     :title,              null: false
      t.decimal    :amount,             precision: 10, scale: 2, null: false
      t.string     :creditor,           null: false
      t.text       :description
      t.date       :due_date,           null: false
      t.string     :status,             default: "pending", null: false
      t.string     :debt_type,          null: false
      t.decimal    :interest_rate,      precision: 5, scale: 2
      t.boolean    :is_recurring,       default: false
      t.string     :recurring_period
      t.string     :original_currency,  default: "USD"
      t.integer    :original_amount_cents
      t.timestamps
    end

    add_index :debts, :due_date
    add_index :debts, [:user_id, :status]
    add_index :debts, :original_currency
  end
end
