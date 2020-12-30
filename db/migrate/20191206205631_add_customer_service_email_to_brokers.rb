class AddCustomerServiceEmailToBrokers < ActiveRecord::Migration[5.1]
  def change
    add_column :brokers, :customer_service_email, :string
  end
end
