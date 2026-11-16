class AddLegalNameToCustomers < ActiveRecord::Migration[8.1]
  class Customer < ActiveRecord::Base; end

  def up
    add_column :customers, :legal_name, :string

    Customer.reset_column_information
    Customer.find_each do |customer|
      name = customer.name&.squish
      name = customer.name if Customer.where.not(id: customer.id).exists?(name:)

      customer.update!(legal_name: customer.name&.squish, name:)
    end
  end

  def down = remove_column(:customers, :legal_name)
end
