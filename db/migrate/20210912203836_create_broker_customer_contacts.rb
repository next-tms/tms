class CreateBrokerCustomerContacts < ActiveRecord::Migration[6.1]
  def change
    create_table :broker_customer_contacts do |t|
      t.references :broker_customer, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true

      t.timestamps
    end
  end
end
