# frozen_string_literal: true

class AddStandardizedAddressToAddresses < ActiveRecord::Migration[6.1]
  def change
    add_reference :addresses, :standardized_address, null: true, foreign_key: true
  end
end
