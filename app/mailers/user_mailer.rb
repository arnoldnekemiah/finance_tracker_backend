class UserMailer < ApplicationMailer
  default from: 'noreply@financetracker.com'

  def password_reset(user, reset_token)
    @user = user
    @reset_token = reset_token
    # Deep link for Flutter app (customize the scheme to match your app)
    @reset_url = "financetracker://reset-password?token=#{@reset_token}"
    # Fallback web URL for users who don't have the app installed
    @web_fallback_url = "#{ENV['WEB_FALLBACK_URL'] || 'https://your-website.com'}/reset-password?token=#{@reset_token}"
    
    mail(
      to: @user.email,
      subject: 'Reset Your Finance Tracker Password'
    )
  end
end
