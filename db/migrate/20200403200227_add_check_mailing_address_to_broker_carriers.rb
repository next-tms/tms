class AddCheckMailingAddressToBrokerCarriers < ActiveRecord::Migration[6.0]
  def change
    add_reference :broker_carriers, :check_mailing_address, foreign_key: { to_table: :addresses }
  end
end
