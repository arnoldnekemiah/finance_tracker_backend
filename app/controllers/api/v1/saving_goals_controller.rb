class Api::V1::SavingGoalsController < ApplicationController
    load_and_authorize_resource
    
      def index
        saving_goals = current_user.saving_goals
        render json: saving_goals, each_serializer: SavingGoalSerializer
      end

      def show
        saving_goal = current_user.saving_goals.find(params[:id])
        render json: saving_goal
      end

      def create
        saving_goal = current_user.saving_goals.build(saving_goal_params)
        if saving_goal.save
          render json: saving_goal, status: :created
        else
          render json: { errors: saving_goal.errors }, status: :unprocessable_entity
        end
      end

      def update
        saving_goal = current_user.saving_goals.find(params[:id])
        if saving_goal.update(saving_goal_params)
          render json: saving_goal
        else
          render json: { errors: saving_goal.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        saving_goal = current_user.saving_goals.find(params[:id])
        saving_goal.destroy
        head :no_content
      end

      def update_progress
        saving_goal = current_user.saving_goals.find(params[:id])
        if saving_goal.update(current_amount: params[:current_amount])
          render json: saving_goal
        else
          render json: { errors: saving_goal.errors }, status: :unprocessable_entity
        end
      end

      private

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
