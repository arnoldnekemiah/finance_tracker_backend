class Budgets::CreatorService
  def initialize(user, params)
    @user = user
    @params = params
  end

  def call
    budget = @user.budgets.build(@params)
    if budget.save
      { success: true, budget: budget }
    else
      { success: false, errors: budget.errors }
    end
  end
end
