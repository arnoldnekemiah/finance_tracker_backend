class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount
      t.string :category
      t.string :type
      t.datetime :date
      t.text :notes
      t.string :recurring_id

      t.timestamps
    end
  end
end
