require 'rails_helper'

RSpec.describe(DSDC::InvoicePayload) do
  subject(:payload) { described_class.new(body) }

  let(:body) { JSON.parse(file_fixture('dsdc/invoice_request.json').read.sub('SHIPMENT_ID', shipment.load_id.to_s)) }
  let(:broker_carrier) { create(:broker_carrier, days_to_pay_after_invoice_date: 15) }
  let(:shipment) { create(:shipment, :usd, broker_carrier:, pro: 'A7770123') }

  describe '#balance' do
    it { expect(payload.balance).to(eq(Money.from_amount(425.50, 'USD'))) }

    context 'without a currency code' do
      before { body['invoiceHeader']['invoiceAmount'].delete('currencyCode') }

      it { expect(payload.balance).to(eq(Money.from_amount(425.50, Money.default_currency))) }
    end

    context 'with a value that is not a number' do
      before { body['invoiceHeader']['invoiceAmount']['value'] = 'abc' }

      it { expect { payload.balance }.to(raise_error(ArgumentError)) }
    end
  end

  describe '#invoice_date' do
    it { expect(payload.invoice_date).to(eq(Date.new(2026, 11, 1))) }
  end

  describe '#invoice_number' do
    it { expect(payload.invoice_number).to(eq('CARRIER-INV-100')) }
  end

  describe '#mc_matches?' do
    it { expect(payload.mc_matches?(654_321)).to(be(true)) }
    it { expect(payload.mc_matches?(111_111)).to(be(false)) }
    it { expect(payload.mc_matches?(nil)).to(be(true)) }
  end

  describe '#notes' do
    it { expect(payload.notes).to(eq('Delivered on time.')) }

    context 'without comments' do
      before { body.delete('comments') }

      it { expect(payload.notes).to(be_nil) }
    end
  end

  describe '#payment_transaction_attributes' do
    let(:attributes) { payload.payment_transaction_attributes(broker_carrier) }

    it do
      expect(attributes).to(
        eq(
          balance: Money.from_amount(425.50, 'USD'),
          broker_carrier:,
          due_on: Date.new(2026, 12, 1),
          dsdc_invoice: body,
          dsdc_unique_id: 'INV-UNIQUE-1',
          invoice: 'CARRIER-INV-100',
          notes: 'Delivered on time.',
          pro: 'A7770123',
          shipment:
        )
      )
    end

    context 'without a payment due date' do
      before { body['invoiceHeader']['terms'].delete('paymentDueDate') }

      it { expect(attributes[:due_on]).to(eq(Date.new(2026, 11, 16))) }
    end

    context 'without a DOT number' do
      before { body.delete('DOT') }

      it { expect { attributes }.to(raise_error(ActionController::ParameterMissing)) }
    end

    context 'without invoice charges' do
      before { body.delete('invoiceCharges') }

      it { expect { attributes }.to(raise_error(ActionController::ParameterMissing)) }
    end
  end

  describe '#shipment' do
    let(:shipments) { broker_carrier.shipments }

    it { expect(payload.shipment(shipments)).to(eq(shipment)) }

    context 'with the PRO as the shipment ID' do
      before { body['shipmentID'] = 'A7770123' }

      it { expect(payload.shipment(shipments)).to(eq(shipment)) }
    end

    context 'with an unknown shipment ID' do
      before { body['shipmentID'] = 'UNKNOWN' }

      it { expect { payload.shipment(shipments) }.to(raise_error(ActiveRecord::RecordNotFound)) }
    end
  end

  describe '#unique_id' do
    it { expect(payload.unique_id).to(eq('INV-UNIQUE-1')) }
  end
end
