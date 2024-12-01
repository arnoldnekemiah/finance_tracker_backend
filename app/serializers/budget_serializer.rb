class BudgetSerializer < ActiveModel::Serializer
    attributes :id, :category, :limit, :spent, :start_date, :end_date, 
               :remaining_amount, :percentage_used, :is_over_budget
  
    def remaining_amount
      object.limit - object.spent
    end
  
    def percentage_used
      (object.spent / object.limit) * 100
    end
  
    def is_over_budget
      object.spent > object.limit
    end
  end