class AddPaidOnToPayments < ActiveRecord::Migration[6.0]
  def change
    add_column :payments, :paid_on, :date
  end
end
