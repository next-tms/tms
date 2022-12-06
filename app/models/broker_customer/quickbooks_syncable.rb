# frozen_string_literal: true

module BrokerCustomer::QuickbooksSyncable
  extend ActiveSupport::Concern

  included do
    def create_quickbooks_customer
      return nil unless broker.intuit_account&.connected?

      return update_quickbooks_customer unless quickbooks_customer.blank?

      result = QuickbooksAPIClient::Customers.new(broker:).create(self)
      return @quickbooks_customer = nil if result.blank?

      update_columns(quickbooks_customer_id: result.id)
      @quickbooks_customer = result
    end

    def update_quickbooks_customer
      return nil unless broker.intuit_account&.connected?

      return create_quickbooks_customer if quickbooks_customer.blank?

      result = QuickbooksAPIClient::Customers.new(broker:).update(self)
      return @quickbooks_customer = nil if result.blank?

      @quickbooks_customer = result
    end

    def quickbooks_customer
      return nil unless broker.intuit_account&.connected?
      return @quickbooks_customer unless @quickbooks_customer.blank?

      result = nil

      unless quickbooks_customer_id.blank?
        result = QuickbooksAPIClient::Customers.new(broker:).find(quickbooks_customer_id)
      end
      return @quickbooks_customer = result unless result.blank?

      result = QuickbooksAPIClient::Customers.new(broker:).find_by_name(customer.name)
      return nil if result.blank?

      update_columns(quickbooks_customer_id: result.id)
      @quickbooks_customer = result
    end

    def to_quickbooks_customer
      Quickbooks::Model::Customer.new(
        billing_address: office_address.to_quickbooks_physical_address,
        company_name: customer.name,
        display_name: customer.name,
        shipping_address: primary_pickup_address&.to_quickbooks_physical_address
      )
    end
  end
end
