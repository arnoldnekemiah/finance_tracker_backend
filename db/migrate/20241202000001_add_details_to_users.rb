class AddDetailsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :currency, :string, default: 'USD'
    remove_column :users, :name, :string
  end
end
