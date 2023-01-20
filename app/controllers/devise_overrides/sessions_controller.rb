class DeviseOverrides::SessionsController < ::DeviseTokenAuth::SessionsController
  # Prevent session parameter from being passed
  # Unpermitted parameter: session
  wrap_parameters format: []
  before_action :process_sso_auth_token, only: [:create]

  def create
    # Authenticate user via the temporary sso auth token
    if params[:sso_auth_token].present? && @resource.present?
      authenticate_resource_with_sso_token
      yield @resource if block_given?
      render_create_success
    else
      return render_create_error_wrong_otp unless passes_otp_check?

      super
    end
  end

  def render_create_success
    render partial: 'devise/auth', formats: [:json], locals: { resource: @resource }
  end

  private

  def authenticate_resource_with_sso_token
    @token = @resource.create_token
    @resource.save!

    sign_in(:user, @resource, store: false, bypass: false)
    # invalidate the token after the user is signed in
    @resource.invalidate_sso_auth_token(params[:sso_auth_token])
  end

  def process_sso_auth_token
    return if params[:email].blank?

    user = User.find_by(email: params[:email])
    @resource = user if user&.valid_sso_auth_token?(params[:sso_auth_token])
  end

  def passes_otp_check?
    user = User.find_by(email: params[:email])
    return true unless user&.otp_required_for_login?
    return false unless params[:otp_attempt].instance_of?(String)

    user.verify_otp!(params[:otp_attempt])
  end

  def render_create_error_wrong_otp
    render_error(401, I18n.t('errors.signup.incorrect_otp'))
  end
end
