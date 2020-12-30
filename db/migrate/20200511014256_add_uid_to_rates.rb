class AddUidToRates < ActiveRecord::Migration[6.0]
  def change
    add_column :rates, :uid, :string
  end
end
