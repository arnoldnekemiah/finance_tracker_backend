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

  def full_name
    "#{first_name} #{last_name}"
  end
end
