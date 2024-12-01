class TransactionSerializer < ActiveModel::Serializer
    attributes :id, :amount, :category, :type, :date, :notes, :recurring_id
  
    def type
      object.transaction_type
    end
  end