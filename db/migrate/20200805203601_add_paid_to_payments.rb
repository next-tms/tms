class AddPaidToPayments < ActiveRecord::Migration[6.0]
  def change
    add_monetize :payments, :paid
  end
end
