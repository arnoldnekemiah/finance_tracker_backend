class UserMailer < ApplicationMailer
  def reset_password_otp(user)
    @user = user
    @otp = user.reset_otp
    mail(to: @user.email, subject: 'Your Password Reset Code — Accountanta')
  end
end
