class AddBankToPayments < ActiveRecord::Migration[6.0]
  def change
    add_reference :payments, :bank, null: true, foreign_key: true
  end
end
