class AddReceiveEmailNotificationsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :receive_email_notifications, :boolean, default: true
  end
end
