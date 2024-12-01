class CreateRecurringTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :recurring_transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount
      t.string :category
      t.text :description
      t.string :period
      t.datetime :start_date
      t.datetime :end_date
      t.boolean :is_active

      t.timestamps
    end
  end
end
