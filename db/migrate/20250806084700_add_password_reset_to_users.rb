class AddPasswordResetToUsers < ActiveRecord::Migration[7.1]
  def change
    # Only add columns that don't exist
    add_column :users, :reset_password_sent_at, :datetime unless column_exists?(:users, :reset_password_sent_at)
    add_column :users, :active, :boolean, default: true, null: false unless column_exists?(:users, :active)
    
    # Add indexes if they don't exist
    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)
    add_index :users, :active unless index_exists?(:users, :active)
  end
end
