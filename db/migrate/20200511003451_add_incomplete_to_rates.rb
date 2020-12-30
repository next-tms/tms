class AddIncompleteToRates < ActiveRecord::Migration[6.0]
  def change
    add_column :rates, :incomplete, :boolean
  end
end
