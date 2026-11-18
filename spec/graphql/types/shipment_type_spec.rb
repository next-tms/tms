require 'rails_helper'

RSpec.describe(Types::ShipmentType) do
  subject(:result) { LiftoffSchema.execute(query, context: { authorizable: }).to_h }

  let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:dispatch) } }
  let(:broker_carrier) { create(:broker_carrier) }
  let(:items) { result.dig('data', 'shipments', 'items') }
  let(:query) do
    <<~GRAPHQL
      {
        shipments {
          items { carrier { id } carrierAccount { id } customer { id } items { id } receiverAddress { id } shipperAddress { id } status }
        }
      }
    GRAPHQL
  end

  let!(:shipments) { create_list(:shipment, 2, broker_carrier:) }

  def queries_from(table_name)
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      queries << payload[:sql] if payload[:sql].start_with?("SELECT \"#{table_name}\".* FROM \"#{table_name}\" WHERE")
    end
    result

    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  it { expect(items.first['status']).to(eq(shipments.first.status)) }
  it { expect(items.pluck('carrier')).to(all(eq('id' => broker_carrier.carrier_id.to_s))) }
  it { expect(items.pluck('carrierAccount')).to(all(eq('id' => broker_carrier.id.to_s))) }
  it { expect(items.pluck('customer')).to(eq(shipments.map { |shipment| { 'id' => shipment.broker_customer_id.to_s } })) }
  it { expect(items.pluck('items')).to(eq(shipments.map { |shipment| shipment.items.map { |item| { 'id' => item.id.to_s } } })) }
  it { expect(queries_from('addresses').size).to(eq(2)) }
  it { expect(queries_from('broker_carriers').size).to(eq(1)) }
  it { expect(queries_from('broker_customers').size).to(eq(1)) }
  it { expect(queries_from('carriers').size).to(eq(1)) }
  it { expect(queries_from('items').size).to(eq(1)) }

  context 'when the user is a carrier' do
    let(:authorizable) { create(:user, companyable: broker_carrier.carrier) }

    it { expect(items.pluck('carrierAccount')).to(all(eq('id' => broker_carrier.id.to_s))) }
    it { expect(items.pluck('customer')).to(all(be_nil)) }
    it { expect(items.pluck('shipperAddress')).to(all(be_present)) }
  end

  describe '#documents' do
    let(:documents) { items.first['documents'] }
    let(:kinds) { documents.pluck('kind') }
    let(:query) { '{ shipments { items { documents { byteSize contentType createdAt filename id kind url } } } }' }

    before do
      allow(DocumentableService).to(receive(:call))
      shipments.each do |shipment|
        shipment.carrier_bol.attach(io: StringIO.new('pdf'), filename: 'carrier_bol.pdf')
        shipment.carrier_pod.attach(io: StringIO.new('pdf'), filename: 'carrier_pod.pdf')
        create(:receivable, shipment:).invoice.attach(io: StringIO.new('pdf'), filename: 'invoice.pdf')
        ['broker_carrier_quote', 'broker_dispatch_sheet', 'broker_ebol', 'broker_quote'].each do |name|
          blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new('pdf'), filename: "#{name}.pdf")
          ActiveStorage::Attachment.create!(blob:, name:, record: shipment)
        end
      end
    end

    it { expect(kinds).to(contain_exactly('CARRIER_QUOTE', 'DISPATCH_SHEET', 'EBOL', 'INVOICE', 'POD', 'QUOTE', 'SCANNED_BOL')) }
    it { expect(documents.first['url']).to(include('/rails/active_storage/blobs/redirect/')) }
    it { expect(documents.pick('filename', 'byteSize')).to(eq(['carrier_bol.pdf', 3])) }
    it { expect(queries_from('active_storage_attachments').size).to(eq(2)) }
    it { expect(queries_from('active_storage_blobs').size).to(eq(1)) }
    it { expect(queries_from('receivables').size).to(eq(1)) }

    context 'when the user is a carrier' do
      let(:authorizable) { create(:user, companyable: broker_carrier.carrier) }

      it { expect(kinds).to(contain_exactly('CARRIER_QUOTE', 'DISPATCH_SHEET', 'EBOL', 'POD', 'SCANNED_BOL')) }
    end

    context 'when the user is a customer' do
      let(:authorizable) { create(:customer_user, companyable: shipments.first.broker_customer) }

      it { expect(kinds).to(contain_exactly('EBOL', 'INVOICE', 'POD', 'QUOTE')) }
    end
  end

  describe '#events' do
    let(:events) { items.first['events'] }
    let(:public_event) { create(:event, public_by_default: true) }
    let(:query) { '{ shipments { items { events { city name occurredAt terminal { address { id } phone } typeCode zipCode } } } }' }
    let(:terminal) { Terminal.create!(address: create(:address), carrier: broker_carrier.carrier, phone: '4155550100') }

    before do
      shipments.each do |shipment|
        create(
          :tracking_event,
          address: create(:address, zip_code: '90210'),
          at: 1.day.ago,
          city: 'Later',
          event: public_event,
          shipment:,
          terminal:
        )
        create(:tracking_event, at: 2.days.ago, city: 'Earlier', event: public_event, shipment:)
        create(:tracking_event, at: 3.days.ago, city: 'Private', event: create(:event, public_by_default: false), shipment:)
      end
    end

    it { expect(events.pluck('city')).to(eq(['Private', 'Earlier', 'Later'])) }
    it { expect(events.last['terminal']).to(eq('address' => { 'id' => terminal.address_id.to_s }, 'phone' => terminal.phone)) }
    it { expect(events.last['zipCode']).to(eq('90210')) }
    it { expect(queries_from('terminals').size).to(eq(1)) }
    it { expect(queries_from('tracking_events').size).to(eq(1)) }

    context 'when the user is a customer' do
      let(:authorizable) { create(:customer_user, companyable: shipments.first.broker_customer) }

      it { expect(events.pluck('city')).to(eq(['Earlier', 'Later'])) }
    end

    context 'when the user is a carrier' do
      let(:authorizable) { create(:user, companyable: broker_carrier.carrier) }

      it { expect(events.pluck('city')).to(eq(['Earlier', 'Later'])) }

      context 'when the carrier is the tracking carrier' do
        before { shipments.each { |shipment| shipment.update!(tracking_carrier: broker_carrier.carrier) } }

        it { expect(events.pluck('city')).to(eq(['Private', 'Earlier', 'Later'])) }
      end
    end
  end

  describe '#id' do
    let(:query) { '{ shipments { items { id } } }' }

    it { expect(items.pluck('id')).to(match_array(shipments.map { |shipment| shipment.load_id.to_s })) }
  end

  describe '#picked_up' do
    let(:query) { '{ shipments { items { pickedUp } } }' }
    let!(:shipments) do
      [create(:shipment, broker_carrier:), create(:shipment, broker_carrier:, delivered_at: nil, dispatched_at: nil, picked_up_at: nil)]
    end

    it { expect(items.pluck('pickedUp')).to(contain_exactly(true, false)) }
  end

  describe 'money fields' do
    let(:charge_fields) { 'carrierChargeCents carrierChargeCurrency totalChargesCents totalChargesCurrency' }
    let(:cost_fields) { 'carrierCostCents carrierCostCurrency totalCostCents totalCostCurrency' }
    let(:errors) { result['errors'].pluck('message') }
    let(:fields) { "#{charge_fields} #{cost_fields}" }
    let(:query) { "{ shipments { items { #{fields} } } }" }

    it { expect(items.first.values).to(all(be_present)) }

    context 'when the user is a carrier' do
      let(:authorizable) { create(:user, companyable: broker_carrier.carrier) }

      it { expect(errors).to(include("Field 'carrierChargeCents' doesn't exist on type 'Shipment'")) }

      context 'with only cost fields' do
        let(:fields) { cost_fields }

        it { expect(items.first.values).to(all(be_present)) }
      end
    end

    context 'when the user is a customer' do
      let(:authorizable) { create(:customer_user, companyable: shipments.first.broker_customer) }

      it { expect(errors).to(include("Field 'carrierCostCents' doesn't exist on type 'Shipment'")) }

      context 'with only charge fields' do
        let(:fields) { charge_fields }

        it { expect(items.first.values).to(all(be_present)) }
      end
    end
  end

  describe 'note fields' do
    let(:errors) { result['errors'].pluck('message') }
    let(:query) { '{ shipments { items { brokerAndBrokerCustomerNotes brokerNotes } } }' }

    let!(:shipments) { create_list(:shipment, 1, broker_and_broker_customer_notes: 'Shared', broker_carrier:, broker_notes: 'Internal') }

    it { expect(items.first).to(eq('brokerAndBrokerCustomerNotes' => 'Shared', 'brokerNotes' => 'Internal')) }

    context 'when the user is a carrier' do
      let(:authorizable) { create(:user, companyable: broker_carrier.carrier) }

      it { expect(errors).to(include("Field 'brokerAndBrokerCustomerNotes' doesn't exist on type 'Shipment'")) }
      it { expect(errors).to(include("Field 'brokerNotes' doesn't exist on type 'Shipment'")) }
    end

    context 'when the user is a customer' do
      let(:authorizable) { create(:customer_user, companyable: shipments.first.broker_customer) }

      it { expect(errors).to(eq(["Field 'brokerNotes' doesn't exist on type 'Shipment'"])) }

      context 'with only shared notes' do
        let(:query) { '{ shipments { items { brokerAndBrokerCustomerNotes } } }' }

        it { expect(items.first).to(eq('brokerAndBrokerCustomerNotes' => 'Shared')) }
      end
    end
  end
end
