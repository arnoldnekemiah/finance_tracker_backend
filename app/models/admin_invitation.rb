class AdminInvitation < ApplicationRecord
  belongs_to :inviter, class_name: 'User', foreign_key: :invited_by_id

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :pending, -> { where(accepted_at: nil).where('expires_at > ?', Time.current) }
  scope :expired, -> { where(accepted_at: nil).where('expires_at <= ?', Time.current) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  before_validation :generate_token, on: :create
  before_validation :set_expiry, on: :create

  def expired?
    expires_at < Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def pending?
    !accepted? && !expired?
  end

  def accept!(user)
    update!(accepted_at: Time.current)
    user.update!(admin: true, invited_by_id: invited_by_id, invitation_token: nil)
  end

  def time_remaining
    return 0 if expired?
    ((expires_at - Time.current) / 1.hour).round(1)
  end

  private

  def generate_token
    self.token = SecureRandom.hex(32) if token.blank?
  end

  def set_expiry
    self.expires_at = 7.days.from_now if expires_at.blank?
  end
end
