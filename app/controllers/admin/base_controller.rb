class Admin::BaseController < ApplicationController
  include AdminAuthenticatable

  skip_before_action :authenticate_user!
  before_action :authenticate_admin_user!

  layout 'admin'

  private

  def current_user
    current_admin_user
  end
end
