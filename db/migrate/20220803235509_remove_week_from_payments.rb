class RemoveWeekFromPayments < ActiveRecord::Migration[7.0]
  def change
    remove_column :payments, :week, :integer
  end
end
