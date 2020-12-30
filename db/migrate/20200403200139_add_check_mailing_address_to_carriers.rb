class AddCheckMailingAddressToCarriers < ActiveRecord::Migration[6.0]
  def change
    add_reference :carriers, :check_mailing_address, foreign_key: { to_table: :addresses }
  end
end
