class CreateDebts < ActiveRecord::Migration[7.1]
  def change
    create_table :debts, id: :uuid do |t|
      t.references :user,          type: :uuid, null: false, foreign_key: true
      t.string     :title,         null: false
      t.decimal    :amount,        precision: 15, scale: 2, null: false
      t.string     :creditor,      null: false
      t.datetime   :due_date,      null: false
      t.string     :status,        default: 'pending'  # pending, paid, overdue
      t.string     :debt_type,     default: 'loan'
      t.decimal    :interest_rate, precision: 5, scale: 2
      t.boolean    :is_recurring,  default: false
      t.timestamps
    end

    add_index :debts, :due_date
    add_index :debts, [:user_id, :status]
  end
end
