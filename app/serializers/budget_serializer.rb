class BudgetSerializer < ActiveModel::Serializer
  attributes :id, :category, :limit, :spent, :start_date, :end_date, :period,
             :percentage_used, :remaining_amount, :over_budget, :days_remaining

  def category
    {
      id: object.category.id,
      name: object.category.name,
      icon: object.category.icon,
      color: object.category.color,
      transaction_type: object.category.transaction_type
    }
  end

  def percentage_used
    object.percentage_used
  end

  def remaining_amount
    object.remaining_amount
  end

  def over_budget
    object.over_budget?
  end

  def days_remaining
    object.days_remaining
  end
end
