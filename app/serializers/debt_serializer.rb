class DebtSerializer < ActiveModel::Serializer
  attributes :id, :title, :amount, :creditor, :description, :due_date, 
             :status, :debt_type, :interest_rate, :is_recurring, 
             :recurring_period, :created_at, :updated_at, :overdue, 
             :days_until_due

  def overdue
    object.overdue?
  end

  def days_until_due
    object.days_until_due
  end
end
