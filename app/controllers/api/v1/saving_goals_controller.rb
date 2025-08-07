class Api::V1::SavingGoalsController < ApplicationController
  skip_before_action :verify_authenticity_token
  load_and_authorize_resource
  before_action :set_saving_goal, only: %i[show update destroy update_progress]
  
  def index
    saving_goals = current_user.saving_goals.includes(:user)
    render json: saving_goals, each_serializer: SavingGoalSerializer
  end

  def show
    render json: @saving_goal, serializer: SavingGoalSerializer
  end

  def create
    saving_goal = current_user.saving_goals.build(saving_goal_params)
    if saving_goal.save
      render json: saving_goal, serializer: SavingGoalSerializer, status: :created
    else
      render json: { errors: saving_goal.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @saving_goal.update(saving_goal_params)
      render json: @saving_goal, serializer: SavingGoalSerializer
    else
      render json: { errors: @saving_goal.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @saving_goal.destroy
    head :no_content
  end

  def update_progress
    progress_amount = params[:progress_amount].to_f
    
    if progress_amount > 0
      @saving_goal.add_progress(progress_amount)
      render json: @saving_goal, serializer: SavingGoalSerializer
    else
      # Direct update of current_amount
      if @saving_goal.update(current_amount: params[:current_amount])
        render json: @saving_goal, serializer: SavingGoalSerializer
      else
        render json: { errors: @saving_goal.errors }, status: :unprocessable_entity
      end
    end
  end

  private

  def set_saving_goal
    @saving_goal = current_user.saving_goals.find(params[:id])
  end

  def saving_goal_params
    params.require(:saving_goal).permit(
      :title,
      :target_amount,
      :current_amount,
      :target_date,
      :notes
    )
  end
end
