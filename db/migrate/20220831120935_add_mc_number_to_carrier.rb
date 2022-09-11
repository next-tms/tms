class AddMcNumberToCarrier < ActiveRecord::Migration[7.0]
  def change
    add_column :carriers, :mc_number, :string, index: true, unique: true
  end
end
