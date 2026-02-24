class CreateSupportMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :support_messages, id: :uuid do |t|
      t.references :user,         type: :uuid, null: false, foreign_key: true
      t.string     :email
      t.string     :display_name
      t.string     :message_type  # support, bug
      t.text       :message,      null: false
      t.string     :status,       default: 'new'
      t.string     :app_version
      t.string     :build_number
      t.string     :platform
      t.timestamps
    end
  end
end
