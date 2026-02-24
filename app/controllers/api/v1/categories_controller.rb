class Api::V1::CategoriesController < ApplicationController
  include Authenticatable
  before_action :set_category, only: %i[show update destroy]

  def index
    categories = current_user.categories
    render json: { status: 'success', data: categories.map { |c| CategorySerializer.new(c).as_json } }
  end

  def show
    render json: { status: 'success', data: CategorySerializer.new(@category).as_json }
  end

  def create
    category = current_user.categories.build(category_params)
    if category.save
      render json: { status: 'success', data: CategorySerializer.new(category).as_json }, status: :created
    else
      render json: { status: 'error', error: category.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    if @category.update(category_params)
      render json: { status: 'success', data: CategorySerializer.new(@category).as_json }
    else
      render json: { status: 'error', error: @category.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    head :no_content
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.permit(:name, :icon, :color, :transaction_type, :parent_category_id)
  end
end
