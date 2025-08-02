class Api::V1::CategoriesController < ApplicationController
  load_and_authorize_resource
  before_action :set_category, only: %i[show update destroy]

  def index
    categories = current_user.categories
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

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :icon, :color, :transaction_type)
  end
end
