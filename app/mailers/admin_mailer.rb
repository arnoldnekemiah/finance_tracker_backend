class AdminMailer < ApplicationMailer
  def send_invitation(invitation)
    @invitation = invitation
    @accept_url = admin_accept_invitation_url(token: invitation.token)
    @inviter = invitation.inviter
    mail(to: invitation.email, subject: 'You have been invited to Accountanta Admin')
  end

  def admin_password_reset_otp(user)
    @user = user
    @otp = user.reset_otp
    mail(to: @user.email, subject: 'Admin Password Reset Code — Accountanta')
  end

  def admin_session_alert(user, ip_address, user_agent)
    @user = user
    @ip_address = ip_address
    @user_agent = user_agent
    @login_time = Time.current
    mail(to: @user.email, subject: 'New Admin Login Detected — Accountanta')
  end
end
