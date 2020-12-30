class AddAlwaysShowQuotesBasedOnCalculatedClassesToBrokerCustomers < ActiveRecord::Migration[6.0]
  def change
    add_column :broker_customers, :always_show_quotes_based_on_calculated_classes, :boolean, default: true
  end
end
