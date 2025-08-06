class AddAdminToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :admin, :boolean, default: false
    add_column :users, :active, :boolean, default: true, null: false
    
    add_index :users, :admin
    add_index :users, :active
  end
end
