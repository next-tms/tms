class AddDaysToPayAfterInvoiceDateToBrokerCarriers < ActiveRecord::Migration[6.0]
  def change
    add_column :broker_carriers, :days_to_pay_after_invoice_date, :integer, default: 30
  end
end
