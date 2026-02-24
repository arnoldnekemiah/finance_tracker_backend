class Api::V1::SavingGoalsController < ApplicationController
  include Authenticatable
  before_action :set_saving_goal, only: %i[show update destroy]

  def index
    saving_goals = current_user.saving_goals.order(created_at: :desc)
    render json: { status: 'success', data: saving_goals.map { |sg| SavingGoalSerializer.new(sg).as_json } }
  end

  def show
    render json: { status: 'success', data: SavingGoalSerializer.new(@saving_goal).as_json }
  end

  def create
    saving_goal = current_user.saving_goals.build(saving_goal_params)
    if saving_goal.save
      render json: { status: 'success', data: SavingGoalSerializer.new(saving_goal).as_json }, status: :created
    else
      render json: { status: 'error', error: saving_goal.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    if @saving_goal.update(saving_goal_params)
      render json: { status: 'success', data: SavingGoalSerializer.new(@saving_goal).as_json }
    else
      render json: { status: 'error', error: @saving_goal.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    @saving_goal.destroy
    head :no_content
  end

  private

  def set_saving_goal
    @saving_goal = current_user.saving_goals.find(params[:id])
  end

  def saving_goal_params
    params.permit(:title, :target_amount, :current_amount, :target_date, :notes)
  end
end
