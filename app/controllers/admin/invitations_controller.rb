class Admin::InvitationsController < Admin::BaseController
  skip_before_action :authenticate_admin_user!, only: [:show, :accept]

  def index
    @pending_invitations = AdminInvitation.pending.includes(:inviter).order(created_at: :desc)
    @accepted_invitations = AdminInvitation.accepted.includes(:inviter).order(accepted_at: :desc).limit(20)

    respond_to do |format|
      format.html
      format.json {
        render json: {
          pending: @pending_invitations.map { |i| invitation_json(i) },
          accepted: @accepted_invitations.map { |i| invitation_json(i) }
        }
      }
    end
  end

  def create
    email = params[:email]&.downcase&.strip

    if email.blank?
      return respond_with_error('Email is required')
    end

    if User.find_by(email: email)&.admin?
      return respond_with_error('This user is already an admin')
    end

    if AdminInvitation.pending.exists?(email: email)
      return respond_with_error('An invitation is already pending for this email')
    end

    invitation = AdminInvitation.new(email: email, invited_by_id: current_admin_user.id)

    if invitation.save
      AdminMailer.send_invitation(invitation).deliver_later
      log_admin_action('invitation_sent', details: "Invited #{email}")

      respond_to do |format|
        format.html { redirect_to admin_invitations_path, notice: "Invitation sent to #{email}" }
        format.json { render json: { message: "Invitation sent to #{email}", invitation: invitation_json(invitation) }, status: :created }
      end
    else
      respond_with_error(invitation.errors.full_messages.join(', '))
    end
  end

  def show
    @invitation = AdminInvitation.find_by(token: params[:token])

    if @invitation.nil? || @invitation.expired?
      redirect_to admin_login_path, alert: 'This invitation is invalid or has expired.'
      return
    end

    if @invitation.accepted?
      redirect_to admin_login_path, notice: 'This invitation has already been accepted.'
      return
    end

    render layout: false
  end

  def accept
    @invitation = AdminInvitation.find_by(token: params[:token])

    if @invitation.nil? || @invitation.expired? || @invitation.accepted?
      redirect_to admin_login_path, alert: 'This invitation is invalid or has expired.'
      return
    end

    existing_user = User.find_by(email: @invitation.email)

    if existing_user
      @invitation.accept!(existing_user)
      AdminAuditLog.log(user: existing_user, action: 'invitation_accepted', request: request)
      redirect_to admin_login_path, notice: 'Admin access granted. Please log in.'
    else
      user = User.new(
        email: @invitation.email,
        first_name: params[:first_name],
        last_name: params[:last_name],
        password: params[:password],
        password_confirmation: params[:password_confirmation],
        admin: true,
        provider: 'email',
        jti: SecureRandom.uuid
      )

      if user.save
        @invitation.accept!(user)
        AdminAuditLog.log(user: user, action: 'invitation_accepted', request: request)
        redirect_to admin_login_path, notice: 'Account created! Please log in.'
      else
        flash.now[:alert] = user.errors.full_messages.join(', ')
        render :show, layout: false
      end
    end
  end

  def destroy
    invitation = AdminInvitation.find(params[:id])
    log_admin_action('invitation_revoked', details: "Revoked invitation for #{invitation.email}")
    invitation.destroy

    respond_to do |format|
      format.html { redirect_to admin_invitations_path, notice: 'Invitation revoked.' }
      format.json { render json: { message: 'Invitation revoked' } }
    end
  end

  private

  def respond_with_error(message)
    respond_to do |format|
      format.html { redirect_to admin_invitations_path, alert: message }
      format.json { render json: { error: message }, status: :unprocessable_entity }
    end
  end

  def invitation_json(invitation)
    {
      id: invitation.id,
      email: invitation.email,
      invited_by: invitation.inviter&.full_name,
      status: invitation.accepted? ? 'accepted' : (invitation.expired? ? 'expired' : 'pending'),
      expires_at: invitation.expires_at,
      accepted_at: invitation.accepted_at,
      time_remaining_hours: invitation.time_remaining,
      created_at: invitation.created_at
    }
  end
end
