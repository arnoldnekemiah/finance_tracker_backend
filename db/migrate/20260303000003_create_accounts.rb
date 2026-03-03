class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.references :user,               null: false, foreign_key: true
      t.string     :name,               null: false
      t.string     :account_type,       null: false
      t.string     :account_number
      t.string     :bank_name
      t.decimal    :balance,            precision: 15, scale: 2, default: 0.0
      t.string     :currency,           default: "USD"
      t.text       :description
      t.boolean    :is_active,          default: true
      t.string     :original_currency,  default: "USD"
      t.integer    :original_amount_cents
      t.timestamps
    end

    add_index :accounts, [:user_id, :account_type]
    add_index :accounts, :is_active
    add_index :accounts, :original_currency
  end
end
