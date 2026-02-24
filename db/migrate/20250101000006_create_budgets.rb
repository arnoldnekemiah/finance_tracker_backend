class CreateBudgets < ActiveRecord::Migration[7.1]
  def change
    create_table :budgets, id: :uuid do |t|
      t.references :user,        type: :uuid, null: false, foreign_key: true
      t.references :category,    type: :uuid, foreign_key: true
      t.decimal    :limit,       precision: 15, scale: 2, null: false
      t.decimal    :spent,       precision: 15, scale: 2, default: 0.0
      t.string     :period,      null: false  # weekly, monthly, quarterly, yearly
      t.datetime   :start_date,  null: false
      t.datetime   :end_date,    null: false
      t.timestamps
    end
  end
end
