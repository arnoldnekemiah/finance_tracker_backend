class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    # Create accounts table for manual tracking
    create_table :accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :account_type, null: false
      t.string :account_number
      t.string :bank_name
      t.decimal :balance, precision: 15, scale: 2, default: 0.0
      t.string :currency, default: 'USD'
      t.text :description
      t.boolean :is_active, default: true
      
      t.timestamps
    end

    # Add indexes for performance
    add_index :accounts, [:user_id, :account_type]
    add_index :accounts, :is_active
  end
end
