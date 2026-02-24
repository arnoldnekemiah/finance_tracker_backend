class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts, id: :uuid do |t|
      t.references :user,         type: :uuid, null: false, foreign_key: true
      t.string     :name,         null: false
      t.string     :account_type, default: 'regular'  # regular, debt, savings
      t.decimal    :balance,      precision: 15, scale: 2, default: 0.0
      t.string     :currency,     default: 'USD'
      t.string     :bank_name
      t.string     :account_number
      t.boolean    :is_active,    default: true
      t.timestamps
    end

    add_index :accounts, :is_active
    add_index :accounts, [:user_id, :account_type]
  end
end
