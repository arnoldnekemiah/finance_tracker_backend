class AddMissingUserColumnsAndAdminInvitations < ActiveRecord::Migration[7.1]
  def change
    # Add missing columns to users table
    add_column :users, :provider,            :string
    add_column :users, :uid,                 :string
    add_column :users, :photo_url,           :string
    add_column :users, :reset_otp,           :string
    add_column :users, :reset_otp_sent_at,   :datetime
    add_column :users, :otp_attempts,        :integer, default: 0, null: false
    add_column :users, :otp_locked_until,    :datetime
    add_column :users, :admin_role,          :string,  default: 'admin'
    add_column :users, :invitation_token,    :string
    add_column :users, :invitation_sent_at,  :datetime
    add_column :users, :invited_by_id,       :bigint
    add_column :users, :last_admin_login_at, :datetime

    add_index :users, :provider
    add_index :users, [:provider, :uid], unique: true
    add_index :users, :invitation_token, unique: true
    add_foreign_key :users, :users, column: :invited_by_id

    # Create admin_invitations table
    create_table :admin_invitations do |t|
      t.string   :email,         null: false
      t.bigint   :invited_by_id, null: false
      t.string   :token,         null: false
      t.datetime :expires_at,    null: false
      t.datetime :accepted_at
      t.timestamps
    end

    add_index :admin_invitations, :email
    add_index :admin_invitations, :token, unique: true
    add_foreign_key :admin_invitations, :users, column: :invited_by_id
  end
end
