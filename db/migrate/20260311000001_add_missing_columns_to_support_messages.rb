class AddMissingColumnsToSupportMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :support_messages, :email, :string
    add_column :support_messages, :display_name, :string
    add_column :support_messages, :message_type, :string
    add_column :support_messages, :app_version, :string
    add_column :support_messages, :build_number, :string
    add_column :support_messages, :platform, :string
    change_column_default :support_messages, :status, from: nil, to: 'new'
  end
end
