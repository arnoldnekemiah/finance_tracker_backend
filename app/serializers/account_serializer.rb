class AccountSerializer < ActiveModel::Serializer
  attributes :id, :name, :account_type, :bank_name, :balance, :currency, 
             :description, :is_active, :created_at, :updated_at, 
             :formatted_balance, :account_number_masked

  def formatted_balance
    object.formatted_balance
  end

  def account_number_masked
    object.account_number_masked
  end
end
