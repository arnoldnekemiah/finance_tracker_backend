class Category < ApplicationRecord
  belongs_to :user
  belongs_to :parent_category, class_name: 'Category', optional: true
  has_many :subcategories, class_name: 'Category', foreign_key: 'parent_category_id', dependent: :destroy
  has_many :transactions
  has_many :budgets

  validates :name, presence: true
  validates :transaction_type, presence: true, inclusion: { in: %w[income expense] }
  
  scope :parent_categories, -> { where(parent_category_id: nil) }
  scope :subcategories, -> { where.not(parent_category_id: nil) }
  
  def is_parent?
    parent_category_id.nil?
  end
  
  def is_subcategory?
    parent_category_id.present?
  end
end
