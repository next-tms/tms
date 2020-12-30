class AddReceiveSmsNotificationsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :receive_sms_notifications, :boolean
  end
end
