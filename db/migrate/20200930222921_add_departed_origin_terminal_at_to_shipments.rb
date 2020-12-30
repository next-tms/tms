class AddDepartedOriginTerminalAtToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :departed_origin_terminal_at, :datetime
  end
end
