class AdminAuditLog < ApplicationRecord
  belongs_to :user

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_admin, ->(user_id) { where(user_id: user_id) }

  ACTIONS = %w[
    admin_login admin_logout
    user_activated user_deactivated user_deleted
    admin_granted admin_revoked
    invitation_sent invitation_accepted invitation_revoked
    password_reset password_changed
    report_generated data_exported
    settings_updated
  ].freeze

  def self.log(user:, action:, resource: nil, details: nil, request: nil)
    create!(
      user: user,
      action: action,
      resource_type: resource&.class&.name,
      resource_id: resource&.id,
      details: details,
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent&.truncate(500)
    )
  end
end
