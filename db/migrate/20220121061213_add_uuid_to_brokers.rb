# frozen_string_literal: true

class AddUuidToBrokers < ActiveRecord::Migration[7.0]
  def change
    add_column :brokers, :uuid, :uuid, default: 'gen_random_uuid()', index: true, null: false   
  end
end
