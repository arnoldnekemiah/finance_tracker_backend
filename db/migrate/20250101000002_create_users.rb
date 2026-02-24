class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users, id: :uuid do |t|
      # Devise fields
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :jti, null: false

      # Profile
      t.string :first_name,         null: false
      t.string :last_name,          null: false
      t.string :currency,           default: 'USD'
      t.string :preferred_currency, default: 'USD'
      t.string :timezone
      t.string :photo_url

      # Roles & Status
      t.boolean :is_admin,          default: false
      t.boolean :is_active,         default: true

      # OAuth
      t.string :provider            # 'email' or 'google'
      t.string :uid                 # Google OAuth UID

      # OTP Password Reset
      t.string :reset_otp
      t.datetime :reset_otp_sent_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :jti, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :is_admin
    add_index :users, :is_active
    add_index :users, :preferred_currency
  end
end
