class SupportMessageSerializer < ActiveModel::Serializer
  attributes :id, :email, :display_name, :message_type, :message,
             :status, :app_version, :build_number, :platform,
             :created_at, :updated_at
end
