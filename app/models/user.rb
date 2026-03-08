class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, :omniauthable,
         jwt_revocation_strategy: self,
         omniauth_providers: [:google_oauth2]

  has_many :accounts,         dependent: :destroy
  has_many :categories,       dependent: :destroy
  has_many :transactions,     dependent: :destroy
  has_many :budgets,          dependent: :destroy
  has_many :debts,            dependent: :destroy
  has_many :saving_goals,     dependent: :destroy
  has_many :support_messages, dependent: :destroy
  has_many :admin_audit_logs, dependent: :destroy
  has_many :sent_invitations, class_name: 'AdminInvitation', foreign_key: :invited_by_id, dependent: :nullify

  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :password, length: { minimum: 6 }, if: :password_required?

  after_create :create_default_categories, :create_default_account

  scope :admins, -> { where(admin: true) }
  scope :regular_users, -> { where(admin: false) }
  scope :active_users, -> { where(active: true) }

  # Alias methods for compatibility
  alias_attribute :is_admin, :admin
  alias_attribute :is_active, :active

  def admin?
    admin
  end

  # OTP Methods with rate limiting
  def generate_reset_otp!
    if otp_locked_until.present? && Time.current < otp_locked_until
      raise StandardError, "Too many OTP attempts. Try again after #{otp_locked_until.strftime('%H:%M')}"
    end

    self.reset_otp = rand(100_000..999_999).to_s
    self.reset_otp_sent_at = Time.current
    self.otp_attempts = 0
    self.otp_locked_until = nil
    save!
  end

  def verify_reset_otp(otp)
    return false if reset_otp.blank? || reset_otp_sent_at.blank?
    return false if Time.current > reset_otp_sent_at + 10.minutes

    if otp_locked_until.present? && Time.current < otp_locked_until
      return false
    end

    if reset_otp == otp
      true
    else
      increment!(:otp_attempts)
      if otp_attempts >= 3
        update!(otp_locked_until: 30.minutes.from_now)
      end
      false
    end
  end

  def clear_reset_otp!
    update!(reset_otp: nil, reset_otp_sent_at: nil, otp_attempts: 0, otp_locked_until: nil)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def make_admin!
    update!(admin: true)
  end

  def remove_admin!
    update!(admin: false)
  end

  def effective_currency
    preferred_currency || currency || 'USD'
  end

  def record_admin_login!
    update!(last_admin_login_at: Time.current)
  end

  # Google OAuth
  def self.from_google(auth)
    user = User.find_by(email: auth[:email])

    if user
      user.update(provider: 'google', uid: auth[:uid]) if user.provider.blank?
      user
    else
      User.create!(
        email: auth[:email],
        first_name: auth[:first_name] || auth[:email].split('@').first,
        last_name: auth[:last_name] || '',
        provider: 'google',
        uid: auth[:uid],
        photo_url: auth[:photo_url],
        password: Devise.friendly_token[0, 20],
        jti: SecureRandom.uuid
      )
    end
  end

  private

  def password_required?
    provider.present? && provider != 'email' ? false : super
  end

  def create_default_categories
    default_categories = [
      { name: 'Salary', icon: '💰', color: '#4CAF50', transaction_type: 'income' },
      { name: 'Freelance', icon: '💻', color: '#2196F3', transaction_type: 'income' },
      { name: 'Investment', icon: '📈', color: '#9C27B0', transaction_type: 'income' },
      { name: 'Gift', icon: '🎁', color: '#FF9800', transaction_type: 'income' },
      { name: 'Other Income', icon: '💵', color: '#607D8B', transaction_type: 'income' },
      { name: 'Food & Drinks', icon: '🍔', color: '#F44336', transaction_type: 'expense' },
      { name: 'Transport', icon: '🚗', color: '#3F51B5', transaction_type: 'expense' },
      { name: 'Shopping', icon: '🛍️', color: '#E91E63', transaction_type: 'expense' },
      { name: 'Entertainment', icon: '🎬', color: '#FF5722', transaction_type: 'expense' },
      { name: 'Bills & Utilities', icon: '📱', color: '#795548', transaction_type: 'expense' },
      { name: 'Health', icon: '🏥', color: '#00BCD4', transaction_type: 'expense' },
      { name: 'Education', icon: '📚', color: '#673AB7', transaction_type: 'expense' },
      { name: 'Housing', icon: '🏠', color: '#8BC34A', transaction_type: 'expense' },
      { name: 'Personal Care', icon: '💇', color: '#FFC107', transaction_type: 'expense' },
      { name: 'Other Expense', icon: '📦', color: '#9E9E9E', transaction_type: 'expense' }
    ]

    default_categories.each do |cat|
      categories.create!(cat)
    end
  end

  def create_default_account
    accounts.create!(
      name: 'Main Account',
      account_type: 'regular',
      balance: 0.0,
      currency: currency || 'USD'
    )
  end
end
