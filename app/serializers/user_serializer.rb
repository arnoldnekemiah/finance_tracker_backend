class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :first_name, :last_name, :preferred_currency
  
  attribute :currency do |object|
    object.preferred_currency
  end
end
