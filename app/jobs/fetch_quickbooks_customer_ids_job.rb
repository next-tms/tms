# frozen_string_literal: true

class FetchQuickbooksCustomerIdsJob < ApplicationJob
  def perform(broker:)
    return unless broker.intuit_account&.connected?

    quickbooks_customers = QuickbooksApiClient::Customers.new(broker:).find_all

    quickbooks_customers.each do |quickbooks_customer|
      broker_customer = broker
                        .broker_customers
                        .joins(:customer)
                        .where(quickbooks_customer_id: nil)
                        .where('customers.name ILIKE ?', quickbooks_customer.company_name)
                        &.first

      if broker_customer.blank?
        broker_customer = broker
                          .broker_customers
                          .where('customers.name ILIKE ?', quickbooks_customer.display_name)
                          .where(quickbooks_customer_id: nil)
                          .joins(:customer)
                          &.first
      end

      next if broker_customer.blank?

      broker_customer.update(quickbooks_customer_id: quickbooks_customer.id)
    end

    broker_customers = broker
                       .broker_customers
                       .where(quickbooks_customer_id: nil)
                       .includes(:customer)
                       .order('customers.name')

    return if broker_customers.empty?

    QuickbooksMailer.unknown_customers(broker_customers:).deliver_now
  end
end
