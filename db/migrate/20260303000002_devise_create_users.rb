class DeviseCreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      ## Devise fields
      t.string   :email,                  default: "",    null: false
      t.string   :encrypted_password,     default: "",    null: false
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      ## JWT
      t.string   :jti,                                    null: false

      ## Profile
      t.string   :first_name
      t.string   :last_name
      t.string   :currency,               default: "USD"
      t.string   :preferred_currency,     default: "USD", null: false
      t.string   :timezone,               default: "UTC"

      ## Admin & status
      t.boolean  :admin,                  default: false
      t.boolean  :active,                 default: true,   null: false

      t.timestamps
    end

    add_index :users, :email,                unique: true
    add_index :users, :jti,                  unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :admin
    add_index :users, :active
    add_index :users, :preferred_currency
  end
end
