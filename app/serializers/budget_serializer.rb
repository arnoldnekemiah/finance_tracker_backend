class BudgetSerializer < ActiveModel::Serializer
  attributes :id, :limit, :spent, :start_date, :end_date, :created_at, :updated_at, 
             :period, :percentage_used, :remaining_amount, :over_budget, :days_remaining
  
  belongs_to :category

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
