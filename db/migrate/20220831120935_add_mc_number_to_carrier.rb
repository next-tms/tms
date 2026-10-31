class AddMcNumberToCarrier < ActiveRecord::Migration[7.0]
  def change
    add_column :carriers, :mc_number, :string, unique: true
    add_index :carriers, :mc_number
  end
end
