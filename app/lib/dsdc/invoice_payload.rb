class DSDC::InvoicePayload
  HEADER = [:invoiceDate, :invoiceNumber, { invoiceAmount: %i[currencyCode value], terms: %i[paymentDueDate] }].freeze

  attr_reader :body, :params

  def initialize(body)
    @body = body
    @params = ActionController::Parameters.new(body)
  end

  def balance = Money.from_amount(BigDecimal(amount.expect(:value)), amount[:currencyCode].presence || Money.default_currency)
  def invoice_date = Date.iso8601(header.expect(:invoiceDate))
  def invoice_number = header.expect(:invoiceNumber)
  def mc_matches?(mc_number) = mc_number.blank? || params.expect(:MC).to_s.gsub(/\D/, '') == mc_number.to_s
  def notes = Array(params[:comments]).filter_map { |comment| comment[:commentText].presence }.join("\n").presence

  def payment_transaction_attributes(carrier)
    params.expect(:DOT, invoiceCharges: [[:chargeType]])

    shipment = shipment(carrier.shipments)
    broker_carrier = shipment.broker_carrier

    {
      balance:,
      broker_carrier:,
      due_on: payment_due_date || (invoice_date + broker_carrier.days_to_pay_after_invoice_date.to_i.days),
      dsdc_invoice: body,
      dsdc_unique_id: unique_id,
      invoice: invoice_number,
      notes:,
      pro: shipment.pro,
      shipment:
    }
  end

  def shipment(shipments)
    shipment_id = params.expect(:shipmentID)

    (shipments.find_by(load_id: shipment_id) if shipment_id.match?(/\A\d+\z/)) || shipments.where(pro: shipment_id).sole
  end

  def unique_id = params.expect(:uniqueID)

  private

  def amount = header.expect(invoiceAmount: %i[currencyCode value])
  def header = @header ||= params.expect(invoiceHeader: HEADER)
  def payment_due_date = header.dig(:terms, :paymentDueDate).presence&.then { |date| Date.iso8601(date) }
end
