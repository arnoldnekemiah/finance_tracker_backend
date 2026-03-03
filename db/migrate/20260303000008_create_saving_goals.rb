class CreateSavingGoals < ActiveRecord::Migration[7.1]
  def change
    create_table :saving_goals do |t|
      t.references :user,               null: false, foreign_key: true
      t.string     :title
      t.decimal    :target_amount
      t.decimal    :current_amount
      t.datetime   :target_date
      t.text       :notes
      t.string     :original_currency,  default: "USD"
      t.integer    :original_amount_cents
      t.timestamps
    end

    add_index :saving_goals, :original_currency
  end
end
