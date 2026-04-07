class FetchBrokerCustomerQuickbooksCustomerIdsJob < ApplicationJob
  def perform(broker:)
    return unless broker.intuit_account&.connected?

    broker_customers = broker
                       .broker_customers
                       .where(quickbooks_customer_id: nil)
                       .includes(:customer)

    broker_customer_ids = []

    broker_customers.find_each.each do |broker_customer|
      quickbooks_customer = broker_customer.quickbooks_customer

      unless quickbooks_customer.blank?
        broker_customer.update_columns(quickbooks_customer_id: quickbooks_customer.id)
        next
      end

      receivable = broker_customer.receivables.where.not(quickbooks_invoice_id: nil)&.last

      unless receivable.blank?
        quickbooks_customer_id = receivable.quickbooks_invoice&.customer_ref&.value

        if quickbooks_customer_id.blank?
          broker_customer_ids << broker_customer.id
          next
        end

        broker_customer.update_columns(quickbooks_customer_id:)
        next
      end

      broker_customer_ids << broker_customer.id
    end

    return if broker_customer_ids.empty?

    broker_customers = BrokerCustomer
                       .where(id: broker_customer_ids)
                       .includes(:customer)
                       .order('customers.name')

    QuickbooksMailer.unknown_customers(broker_customers:).deliver_now
  end
end
