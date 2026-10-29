class AddACHToBrokerCarriers < ActiveRecord::Migration[8.1]
  def change
    add_column(:broker_carriers, :encrypted_ach_account_number, :string)
    add_column(:broker_carriers, :encrypted_ach_bank_name, :string)
    add_column(:broker_carriers, :encrypted_ach_routing_number, :string)
  end
end
