class DefaultCategoryCreatorService
  def initialize(user)
    @user = user
  end

  def call
    DEFAULT_CATEGORIES.each do |category_attrs|
      @user.categories.find_or_create_by!(name: category_attrs[:name]) do |category|
        category.color = category_attrs[:color]
        category.icon = category_attrs[:icon]
        category.transaction_type = category_attrs[:transaction_type]
      end
    end
  end

  private

  DEFAULT_CATEGORIES = [
    { name: 'Food', color: '#FF6B6B', icon: 'fas fa-utensils', transaction_type: 'expense' },
    { name: 'Electricity', color: '#4ECDC4', icon: 'fas fa-bolt', transaction_type: 'expense' },
    { name: 'Water', color: '#45B7D1', icon: 'fas fa-water', transaction_type: 'expense' },
    { name: 'Fees/Tuition', color: '#96CEB4', icon: 'fas fa-graduation-cap', transaction_type: 'expense' },
    { name: 'Personal', color: '#FFEAA7', icon: 'fas fa-user', transaction_type: 'expense' },
    { name: 'Income', color: '#98D8C8', icon: 'fas fa-money-bill-wave', transaction_type: 'income' },
    { name: 'Other', color: '#DDA0DD', icon: 'fas fa-ellipsis-h', transaction_type: 'expense' }
  ].freeze
end
