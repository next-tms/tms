# frozen_string_literal: true

class AddEncryptedAPIKeyToBrokerCarriers < ActiveRecord::Migration[7.0]
  def change
    add_column :broker_carriers, :encrypted_api_key, :string, default: nil
  end
end
