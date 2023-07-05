# frozen_string_literal: true

class AddLinearFtToShipments < ActiveRecord::Migration[7.0]
  def change
    add_column(:shipments, :linear_ft, :integer)
  end
end
