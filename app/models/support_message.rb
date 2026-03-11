class SupportMessage < ApplicationRecord
  belongs_to :user

  before_validation :set_default_status

  validates :message, presence: true
  validates :message_type, inclusion: { in: %w[support bug] }, allow_nil: true
  validates :status, inclusion: { in: %w[new in_progress resolved closed] }

  scope :unresolved, -> { where(status: %w[new in_progress]) }
  scope :by_type, ->(type) { where(message_type: type) }

  private

  def set_default_status
    self.status ||= 'new'
  end
end
