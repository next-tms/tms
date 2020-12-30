class AddWeekToPayments < ActiveRecord::Migration[6.0]
  def change
    add_column :payments, :week, :integer
  end
end
