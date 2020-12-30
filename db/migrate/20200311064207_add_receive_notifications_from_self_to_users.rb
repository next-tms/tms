class AddReceiveNotificationsFromSelfToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :receive_notifications_from_self, :boolean, default: true
  end
end
