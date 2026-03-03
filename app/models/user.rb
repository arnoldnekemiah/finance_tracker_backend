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

  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :password, length: { minimum: 6 }, if: :password_required?

  after_create :create_default_categories, :create_default_account

  # Admin scopes
  scope :admins, -> { where(is_admin: true) }
  scope :regular_users, -> { where(is_admin: false) }
  scope :active_users, -> { where(is_active: true) }

  # OTP Methods
  def generate_reset_otp!
    self.reset_otp = rand(100_000..999_999).to_s
    self.reset_otp_sent_at = Time.current
    save!
  end

  def verify_reset_otp(otp)
    return false if reset_otp.blank? || reset_otp_sent_at.blank?
    return false if Time.current > reset_otp_sent_at + 10.minutes
    reset_otp == otp
  end

  def clear_reset_otp!
    update!(reset_otp: nil, reset_otp_sent_at: nil)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def admin?
    is_admin == true
  end

  def make_admin!
    update!(is_admin: true)
  end

  def remove_admin!
    update!(is_admin: false)
  end

  def effective_currency
    preferred_currency || currency || 'USD'
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
        password: Devise.friendly_token[0, 20]
      )
    end
  end

  private

  def password_required?
    respond_to?(:provider) && provider.present? && provider != 'email' ? false : super
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
