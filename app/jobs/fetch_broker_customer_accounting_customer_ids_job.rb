class FetchBrokerCustomerAccountingCustomerIdsJob < ApplicationJob
  # @note Jobs enqueued before Broker removal carry a Broker GlobalID that can no longer load
  rescue_from(ActiveJob::DeserializationError) { self.class.perform_later }

  def perform
    return unless Accounting.connected?

    broker_customers = BrokerCustomer.where(accounting_customer_id: nil).includes(:customer)

    broker_customer_ids = []

    broker_customers.find_each.each do |broker_customer|
      accounting_customer = broker_customer.accounting_customer

      unless accounting_customer.blank?
        broker_customer.update_columns(accounting_customer_id: accounting_customer.id)
        next
      end

      receivable = broker_customer.receivables.where.not(accounting_invoice_id: nil)&.last

      unless receivable.blank?
        accounting_customer_id = receivable.accounting_invoice&.customer_id

        if accounting_customer_id.blank?
          broker_customer_ids << broker_customer.id
          next
        end

        broker_customer.update_columns(accounting_customer_id:)
        next
      end

      broker_customer_ids << broker_customer.id
    end

    return if broker_customer_ids.empty?

    broker_customers = BrokerCustomer
                       .where(id: broker_customer_ids)
                       .includes(:customer)
                       .order('customers.name')

    AccountingMailer.unknown_customers(broker_customers:).deliver_now
  end
end
