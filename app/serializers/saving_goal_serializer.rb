class SavingGoalSerializer < ActiveModel::Serializer
    attributes :id, :title, :target_amount, :current_amount, :target_date, :notes,
               :progress_percentage, :is_achieved, :days_remaining
  
    def progress_percentage
      (object.current_amount / object.target_amount) * 100
    end
  
    def is_achieved
      object.current_amount >= object.target_amount
    end
  
    def days_remaining
      (object.target_date - Date.today).to_i
    end
  end