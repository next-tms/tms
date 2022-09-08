class AddEmailNotificationsBlocklistOnUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :email_notifications_blacklist, :text
  end
end
