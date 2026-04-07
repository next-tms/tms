# frozen_string_literal: true

class AddUuidToBrokers < ActiveRecord::Migration[7.0]
  def change
    add_column :brokers, :uuid, :uuid, default: 'gen_random_uuid()', null: false
add_index :brokers, :uuid
  end
end
