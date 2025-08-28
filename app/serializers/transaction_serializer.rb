class TransactionSerializer < ActiveModel::Serializer
  attributes :id, :transaction_type, :date, :notes, :recurring_id, :payment_method, :formatted_original_amount

  def formatted_original_amount
    object.formatted_original_amount
  end

  belongs_to :category
end