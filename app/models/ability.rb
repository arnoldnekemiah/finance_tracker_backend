# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.persisted?
      # Users can manage their own data
      can :manage, Transaction, user_id: user.id
      can :manage, RecurringTransaction, user_id: user.id
      can :manage, Budget, user_id: user.id
      can :manage, SavingGoal, user_id: user.id
    end
  end
end
