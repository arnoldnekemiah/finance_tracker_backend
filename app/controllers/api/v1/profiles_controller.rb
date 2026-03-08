class Api::V1::ProfilesController < Api::BaseController
  include Authenticatable

  # PUT /api/v1/profile
  def update
    if current_user.update(profile_params)
      render json: { status: 'success', data: user_json(current_user) }
    else
      render json: { status: 'error', error: current_user.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/profile/upload_photo
  def upload_photo
    if params[:photo].present?
      # For now, accept a URL. Active Storage can be added later.
      current_user.update!(photo_url: params[:photo_url] || params[:photo])
      render json: { status: 'success', data: user_json(current_user) }
    else
      render json: { status: 'error', error: 'No photo provided' }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/profile/delete_photo
  def delete_photo
    current_user.update!(photo_url: nil)
    render json: { status: 'success', data: user_json(current_user) }
  end

  # DELETE /api/v1/profile/delete_account
  def delete_account
    current_user.destroy
    render json: { status: 'success', data: { message: 'Account deleted successfully' } }
  end

  private

  def profile_params
    params.permit(:first_name, :last_name, :email, :currency, :preferred_currency, :timezone, :photo_url)
  end

  def user_json(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      currency: user.currency,
      preferred_currency: user.preferred_currency,
      timezone: user.timezone,
      photo_url: user.photo_url,
      is_admin: user.is_admin,
      is_active: user.is_active,
      provider: user.provider,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
