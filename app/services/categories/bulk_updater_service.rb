class Categories::BulkUpdaterService
  def initialize(user, categories_params)
    @user = user
    @categories_params = categories_params
  end

  def call
    updated_categories_count = 0
    errors = []

    Category.transaction do
      @categories_params.each do |params|
        category = @user.categories.find_by(id: params[:id])
        if category
          if category.update(params.except(:id))
            updated_categories_count += 1
          else
            errors << { id: params[:id], errors: category.errors.full_messages }
          end
        else
          errors << { id: params[:id], errors: ["Category not found"] }
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.empty?
      clear_cache
      { success: true, updated_count: updated_categories_count }
    else
      { success: false, errors: errors }
    end
  end

  private

  def clear_cache
    Rails.cache.delete("user_#{@user.id}_categories")
  end
end
