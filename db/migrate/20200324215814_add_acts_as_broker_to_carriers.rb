class AddActsAsBrokerToCarriers < ActiveRecord::Migration[6.0]
  def change
    add_column :carriers, :acts_as_broker, :boolean, default: false
  end
end
