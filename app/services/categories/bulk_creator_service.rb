class Categories::BulkCreatorService
  def initialize(user, categories_params)
    @user = user
    @categories_params = categories_params
  end

  def call
    categories_attributes = @categories_params.map do |params|
      params.merge(user_id: @user.id, created_at: Time.current, updated_at: Time.current)
    end

    begin
      created_categories = Category.insert_all(categories_attributes, returning: %w[id name icon color transaction_type])
      clear_cache
      { success: true, categories: created_categories }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, errors: e.message }
    end
  end

  private

  def clear_cache
    Rails.cache.delete("user_#{@user.id}_categories")
  end
end
