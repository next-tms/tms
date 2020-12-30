class AddRefToAddress < ActiveRecord::Migration[6.0]
  def change
    add_column :addresses, :ref, :string
  end
end
