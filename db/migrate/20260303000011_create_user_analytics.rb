class CreateUserAnalytics < ActiveRecord::Migration[7.1]
  def change
    create_table :user_analytics do |t|
      t.references :user,         null: false, foreign_key: true
      t.string     :event_type,   null: false
      t.json       :event_data,   default: {}, null: false
      t.string     :ip_address
      t.text       :user_agent
      t.timestamps
    end

    add_index :user_analytics, :event_type
    add_index :user_analytics, :created_at
    add_index :user_analytics, [:user_id, :event_type]
    add_index :user_analytics, [:user_id, :created_at]
  end
end
