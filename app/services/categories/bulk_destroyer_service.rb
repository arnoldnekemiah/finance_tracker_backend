class Categories::BulkDestroyerService
  def initialize(user, category_ids)
    @user = user
    @category_ids = category_ids
  end

  def call
    deleted_count = @user.categories.where(id: @category_ids).destroy_all.size

    if deleted_count > 0
      clear_cache
      { success: true, deleted_count: deleted_count }
    else
      { success: false, errors: "Could not delete all categories. Some may not exist or belong to the user." }
    end
  end

  private

  def clear_cache
    Rails.cache.delete("user_#{@user.id}_categories")
  end
end
