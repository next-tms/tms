class AddScacToCarriers < ActiveRecord::Migration[5.1]
  def change
    add_column :carriers, :scac, :string
  end
end
