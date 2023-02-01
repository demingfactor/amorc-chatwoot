# frozen_string_literal: true

class SuperAdmin::Devise::SessionsController < Devise::SessionsController
  def new
    self.resource = resource_class.new(sign_in_params)
  end

  def create
    redirect_to(super_admin_session_path, flash: { error: @error_message }) && return unless valid_credentials?

    sign_in(:super_admin, @super_admin)
    flash.discard
    redirect_to super_admin_users_path
  end

  def destroy
    sign_out
    flash.discard
    redirect_to '/'
  end

  private

  def valid_credentials?
    @super_admin = SuperAdmin.find_by!(email: params[:super_admin][:email])
    raise StandardError, 'Invalid Password' unless @super_admin.valid_password?(params[:super_admin][:password])
    raise StandardError, 'Invalid OTP' unless passes_otp_check?

    true
  rescue StandardError => e
    @error_message = e.message
    false
  end

  def passes_otp_check?
    return true unless @super_admin&.otp_required_for_login?
    return false unless params[:super_admin][:otp_attempt].instance_of?(String)

    @super_admin.verify_otp!(params[:super_admin][:otp_attempt])
  end

  def render_create_error_wrong_otp
    render_error(401, I18n.t('errors.signup.incorrect_otp'))
  end
end
