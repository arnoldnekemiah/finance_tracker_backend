class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, 
         :jwt_authenticatable, jwt_revocation_strategy: self
               
  has_many :transactions, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :saving_goals, dependent: :destroy
  has_many :debts, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :categories, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :currency, presence: true
  validates :preferred_currency, inclusion: { in: -> { CurrencyService.supported_currencies.keys } }

  # Admin scopes
  scope :admins, -> { where(admin: true) }
  scope :regular_users, -> { where(admin: false) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def admin?
    admin == true
  end

  def make_admin!
    update!(admin: true)
  end

  def remove_admin!
    update!(admin: false)
  end
  
  def currency_info
    CurrencyService.supported_currencies[preferred_currency || currency]
  end
  
  def effective_currency
    preferred_currency || currency || 'USD'
  end
end
