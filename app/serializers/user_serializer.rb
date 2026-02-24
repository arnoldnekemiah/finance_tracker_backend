class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :currency,
             :preferred_currency, :timezone, :photo_url,
             :is_admin, :is_active, :provider,
             :created_at, :updated_at
end
