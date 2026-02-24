class CreateSavingGoals < ActiveRecord::Migration[7.1]
  def change
    create_table :saving_goals, id: :uuid do |t|
      t.references :user,           type: :uuid, null: false, foreign_key: true
      t.string     :title,          null: false
      t.decimal    :target_amount,  precision: 15, scale: 2, null: false
      t.decimal    :current_amount, precision: 15, scale: 2, default: 0.0
      t.datetime   :target_date,    null: false
      t.text       :notes
      t.timestamps
    end
  end
end
