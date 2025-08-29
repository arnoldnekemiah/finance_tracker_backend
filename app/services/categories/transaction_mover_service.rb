class Categories::TransactionMoverService
  def initialize(user, from_category_id, to_category_id)
    @user = user
    @from_category_id = from_category_id
    @to_category_id = to_category_id
  end

  def call
    from_category = @user.categories.find_by(id: @from_category_id)
    to_category = @user.categories.find_by(id: @to_category_id)

    if from_category && to_category
      updated_count = from_category.transactions.update_all(category_id: @to_category_id)
      clear_cache
      { success: true, moved_count: updated_count }
    else
      errors = []
      errors << "From category not found" unless from_category
      errors << "To category not found" unless to_category
      { success: false, errors: errors }
    end
  end

  private

  def clear_cache
    Rails.cache.delete("user_#{@user.id}_categories")
  end
end
