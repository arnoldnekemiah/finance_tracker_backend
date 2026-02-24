class TransactionSerializer < ActiveModel::Serializer
  attributes :id, :amount, :original_amount, :original_currency,
             :transaction_type, :category_id, :category_name,
             :date, :description, :from_account_id, :to_account_id,
             :payment_method, :created_at, :updated_at

  def category_name
    object.category_name || object.category&.name
  end
end