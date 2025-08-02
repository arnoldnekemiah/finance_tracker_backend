# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.persisted?
      # Users can manage their own data
      can :manage, Transaction, user_id: user.id
      can :manage, Debt, user_id: user.id
      can :manage, Account, user_id: user.id
      can :manage, Budget, user_id: user.id
      can :manage, SavingGoal, user_id: user.id
      can :manage, Category, user_id: user.id
      
      # Allow users to access their own insights and profile
      can :read, :insights, user_id: user.id
      can :manage, :profile, user_id: user.id
    end
  end
end
