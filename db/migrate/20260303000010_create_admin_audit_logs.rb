class CreateAdminAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :admin_audit_logs do |t|
      t.references :user,          null: false, foreign_key: true
      t.string     :action,        null: false
      t.string     :resource_type
      t.integer    :resource_id
      t.text       :details
      t.string     :ip_address
      t.string     :user_agent
      t.timestamps
    end

    add_index :admin_audit_logs, :action
    add_index :admin_audit_logs, [:resource_type, :resource_id]
  end
end
