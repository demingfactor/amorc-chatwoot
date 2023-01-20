class MfaController < DashboardController
  before_action :set_account_id
  before_action :check_backup_codes, only: :codes
  before_action :check_otp_secret, only: :verify
  layout 'mfa'

  def show; end

  def codes; end

  def verify; end

  def update
    respond_to do |format|
      if otp_valid?
        current_user.update(mfa_params)
        format.html { redirect_to account_mfa_path(@account_id) }
      else
        format.html { redirect_to verify_account_mfa_path(@account_id, invalid: true) }
      end
    end
  end

  def destroy
    current_user.disable_otp!
    redirect_to account_mfa_path(@account_id)
  end

  private

  def set_account_id
    @account_id = params[:account_id]
    redirect_to root_path if @account_id.blank?
  end

  def check_otp_secret
    return true if current_user.otp_secret?

    current_user.set_otp_secret!
  end

  def check_backup_codes
    return true if current_user.otp_backup_codes.present?

    current_user.set_otp_backup_codes!
  end

  def otp_valid?
    current_user.verify_otp!(params[:verify])
  end

  def generate_qrcode(string)
    qrcode = RQRCode::QRCode.new(string)
    qrcode.as_svg(module_size: 4)
  end

  def mfa_params
    params.require(:user).permit({ otp_backup_codes: [] }, :otp_secret, :otp_required_for_login)
  end
end
