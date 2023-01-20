class AddTwoFactorToUsers < ActiveRecord::Migration[6.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :otp_secret
      t.integer :consumed_timestep
      t.boolean :otp_required_for_login
      t.text :otp_backup_codes, array: true
    end
  end
end
