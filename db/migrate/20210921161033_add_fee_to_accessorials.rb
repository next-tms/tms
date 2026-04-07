class AddFeeToAccessorials < ActiveRecord::Migration[6.1]
  def change
    add_column :accessorials, :fee, :boolean, default: false
  end
end
