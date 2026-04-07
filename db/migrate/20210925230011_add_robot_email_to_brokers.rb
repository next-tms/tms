class AddRobotEmailToBrokers < ActiveRecord::Migration[6.1]
  def change
    add_column :brokers, :robot_email, :string
  end
end
