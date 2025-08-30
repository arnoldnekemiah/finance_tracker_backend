class TransactionSerializer < ActiveModel::Serializer
  attributes :id, :transaction_type, :date, :notes, :payment_method, 
             :formatted_original_amount, :account_id, :description

  def formatted_original_amount
    object.formatted_original_amount
  end

  belongs_to :category
end