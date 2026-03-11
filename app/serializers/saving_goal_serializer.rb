class SavingGoalSerializer < ActiveModel::Serializer
  attributes :id, :title, :target_amount, :current_amount, :target_date, :notes, 
             :created_at, :updated_at, :progress_percentage, :remaining_amount, 
             :achieved, :days_remaining, :overdue, :monthly_savings_needed

  def progress_percentage
    object.progress_percentage.to_f
  end

  def remaining_amount
    object.remaining_amount.to_f
  end

  def achieved
    object.achieved?
  end

  def days_remaining
    object.days_remaining
  end

  def overdue
    object.overdue?
  end

  def monthly_savings_needed
    object.monthly_savings_needed.to_f
  end
end
