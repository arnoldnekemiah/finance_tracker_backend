class Api::V1::SupportMessagesController < ApplicationController
  include Authenticatable

  # GET /api/v1/support_messages
  def index
    messages = current_user.support_messages.order(created_at: :desc)
    render json: {
      status: 'success',
      data: messages.map { |m| support_message_json(m) }
    }
  end

  # POST /api/v1/support_messages
  def create
    message = current_user.support_messages.build(support_message_params)
    message.email ||= current_user.email
    message.display_name ||= current_user.full_name

    if message.save
      render json: {
        status: 'success',
        data: support_message_json(message)
      }, status: :created
    else
      render json: {
        status: 'error',
        error: message.errors.full_messages.join(', ')
      }, status: :unprocessable_entity
    end
  end

  private

  def support_message_params
    params.permit(:email, :display_name, :message_type, :message, :app_version, :build_number, :platform)
  end

  def support_message_json(message)
    {
      id: message.id,
      email: message.email,
      display_name: message.display_name,
      message_type: message.message_type,
      message: message.message,
      status: message.status,
      app_version: message.app_version,
      build_number: message.build_number,
      platform: message.platform,
      created_at: message.created_at,
      updated_at: message.updated_at
    }
  end
end
