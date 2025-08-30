class Api::V1::CategoriesController < ApplicationController
  skip_before_action :verify_authenticity_token
  load_and_authorize_resource
  before_action :set_category, only: %i[show update destroy]

  def index
    categories = Rails.cache.fetch("user_#{current_user.id}_categories", expires_in: 1.hour) do
      current_user.categories.to_a
    end
    render json: categories, each_serializer: CategorySerializer
  end

  def show
    render json: @category, serializer: CategorySerializer
  end

  def create
    category = current_user.categories.build(category_params)
    if category.save
      render json: category, serializer: CategorySerializer, status: :created
    else
      render json: { errors: category.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @category.update(category_params)
      render json: @category, serializer: CategorySerializer
    else
      render json: { errors: @category.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    head :no_content
  end

  def bulk_create
    result = Categories::BulkCreatorService.new(current_user, categories_params).call
    if result[:success]
      render json: result[:categories], each_serializer: CategorySerializer, status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def bulk_update
    result = Categories::BulkUpdaterService.new(current_user, bulk_update_categories_params).call
    if result[:success]
      render json: { updated_count: result[:updated_count] }, status: :ok
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def move_transactions
    result = Categories::TransactionMoverService.new(current_user, move_transactions_params[:from_category_id], move_transactions_params[:to_category_id]).call
    if result[:success]
      render json: { moved_count: result[:moved_count] }, status: :ok
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :icon, :color, :transaction_type)
  end

  def categories_params
    params.require(:categories).map do |p|
      p.permit(:name, :icon, :color, :transaction_type, :parent_category_id)
    end
  end

  def bulk_update_categories_params
    params.require(:categories).map do |p|
      p.permit(:id, :name, :icon, :color, :transaction_type, :parent_category_id)
    end
  end

  def bulk_destroy
    result = Categories::BulkDestroyerService.new(current_user, bulk_destroy_category_ids).call
    if result[:success]
      render json: { deleted_count: result[:deleted_count] }, status: :ok
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  private

  def bulk_destroy_category_ids
    params.require(:category_ids)
  end

  def move_transactions_params
    params.require(:move_transactions).permit(:from_category_id, :to_category_id)
  end
end
