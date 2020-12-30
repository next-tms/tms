class AddTimeZoneToAddress < ActiveRecord::Migration[6.0]
  def change
    add_column :addresses, :time_zone, :string
  end
end
