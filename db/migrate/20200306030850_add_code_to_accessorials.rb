class AddCodeToAccessorials < ActiveRecord::Migration[6.0]
  def change
    add_column :accessorials, :code, :string
  end
end
