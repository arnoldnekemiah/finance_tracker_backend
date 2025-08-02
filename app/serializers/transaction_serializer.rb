class TransactionSerializer < ActiveModel::Serializer
  attributes :id, :amount, :type, :date, :notes, :recurring_id, :payment_method
  belongs_to :category
end