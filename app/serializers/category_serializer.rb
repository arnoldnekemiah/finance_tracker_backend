class CategorySerializer < ActiveModel::Serializer
  attributes :id, :name, :icon, :color, :transaction_type
end
