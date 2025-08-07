class AddAdminToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :admin, :boolean, default: false unless column_exists?(:users, :admin)
    
    add_index :users, :admin unless index_exists?(:users, :admin)
  end
end
