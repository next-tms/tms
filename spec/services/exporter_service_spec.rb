require 'rails_helper'

RSpec.describe(ExporterService) do
  subject(:exporter) { described_class.new(records, authorizable:, columns:, headers:) }

  let(:authorizable) { create(:broker_user, companyable: shipment.broker) }
  let(:broker_carrier) { create(:broker_carrier) }
  let(:charge) { Money.new(12_345).format }
  let(:columns) { [ 'load_id', 'status', 'total_charges', 'total_cost', 'shipper_address.zip_code' ] }
  let(:cost) { Money.new(10_000).format }
  let(:customer_user) { create(:customer_user, companyable: shipment.broker_customer) }
  let(:headers) { {} }
  let(:records) { Shipment.where(id: shipment.id) }
  let(:row) { [ shipment.load_id, 'Delivered', charge, cost, shipment.shipper_address.zip_code ] }
  let(:shipment) { create(:shipment, broker_carrier:, carrier_charge_cents: 12_345, carrier_cost_cents: 10_000) }

  before { create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles') }

  describe '.available_columns' do
    subject { described_class.available_columns(Shipment, user) }

    let(:user) { authorizable }

    it { is_expected.to(include('average_density', 'broker_carrier.name', 'broker_notes', 'total_charges', 'total_cost')) }
    it { is_expected.to(include('broker_customer.name', 'shipper_address.zip_code')) }

    context 'when a customer' do
      let(:user) { customer_user }

      it { is_expected.to(include('average_density', 'broker_customer.name', 'shipper_address.zip_code', 'total_charges')) }
      it { is_expected.not_to(include('broker_carrier.name', 'broker_notes', 'carrier_cost', 'total_cost', 'tracking_carrier_pro')) }
    end
  end

  describe '.column_header' do
    it { expect(described_class.column_header(Shipment, 'customer_reference')).to(eq('PO #')) }
    it { expect(described_class.column_header(Shipment, 'shipper_address.zip_code')).to(eq('ZIP code (Shipper address)')) }
  end

  describe '.column_parts' do
    it { expect(described_class.column_parts('load_id')).to(eq([ nil, 'load_id' ])) }
    it { expect(described_class.column_parts('shipper_address.zip_code')).to(eq([ 'shipper_address', 'zip_code' ])) }
    it { expect(described_class.column_parts(:load_id)).to(eq([ nil, 'load_id' ])) }
  end

  describe '.customer_columns' do
    it { expect(described_class.customer_columns(Shipment)).to(eq(described_class.available_columns(Shipment, customer_user))) }
  end

  describe '.default_columns' do
    subject { described_class.default_columns(Shipment, authorizable) }

    it { is_expected.to(include('load_id', 'shipper_address.zip_code')) }
    it { is_expected.not_to(include(*ShipmentPolicy::CUSTOMER_METHODS.map(&:to_s))) }
  end

  describe '.exportable_associations' do
    it { expect(described_class.exportable_associations(Shipment, authorizable)).to(include('broker_carrier', 'broker_customer')) }

    it {
      expect(described_class.exportable_associations(Shipment, customer_user))
        .to(eq([ 'broker_customer', 'receiver_address', 'shipper_address' ]))
    }
  end

  describe '.new' do
    it { expect { described_class.new(records, authorizable: nil) }.to(raise_error(ArgumentError)) }
  end

  describe '#cache_key' do
    it { expect(exporter.cache_key).to(start_with("#{records.cache_key}/#{authorizable.cache_key_with_version}/")) }
    it { expect(exporter.cache_key).not_to(eq(described_class.new(records, authorizable:, columns: [ 'load_id' ]).cache_key)) }
  end

  describe '#cache_key_with_version' do
    it { expect(exporter.cache_key_with_version).to(eq("#{exporter.cache_key}-#{exporter.cache_version}")) }
  end

  describe '#cache_version' do
    subject(:cache_version) { -> { described_class.new(records, authorizable:, columns:).cache_version } }

    let(:columns) { [ 'load_id', 'average_density' ] }
    let(:item) { shipment.items.first }
    let(:shipment) { create(:shipment, :with_items) }

    it { expect { item.reload }.not_to(change(&cache_version)) }
    it { expect { item.update!(weight: item.weight + 1) }.to(change(&cache_version)) }
    it { expect { item.destroy! }.to(change(&cache_version)) }

    context 'with an association column' do
      let(:columns) { [ 'load_id', 'broker_customer.name' ] }

      it { expect { shipment.broker_customer.customer.update!(name: 'Jacks Candy') }.to(change(&cache_version)) }
    end

    context 'with a nested association method' do
      let(:columns) { [ 'load_id', 'palletized_count' ] }

      it { expect { item.packaging.update!(name: 'crate') }.to(change(&cache_version)) }
    end
  end

  describe '#columns' do
    subject { exporter.columns }

    it { is_expected.to(eq(columns)) }

    context 'when a customer' do
      let(:authorizable) { customer_user }

      it { is_expected.to(eq([ 'load_id', 'status', 'total_charges', 'shipper_address.zip_code' ])) }
    end

    context 'with an unknown column' do
      let(:columns) { [ 'load_id', 'destroy', 'shipper_address.destroy' ] }

      it { is_expected.to(eq([ 'load_id' ])) }
    end

    context 'without columns' do
      let(:columns) { nil }

      it { is_expected.to(eq(described_class.default_columns(Shipment, authorizable))) }
    end
  end

  describe '#data' do
    subject { exporter.data }

    let(:data) do
      {
        'load_id' => shipment.load_id,
        'shipper_address' => { 'zip_code' => shipment.shipper_address.zip_code },
        'status' => 'Delivered',
        'total_charges' => charge,
        'total_cost' => cost
      }
    end

    it { is_expected.to(eq([ data ])) }
  end

  describe '#headers' do
    subject { exporter.headers }

    it { is_expected.to(eq([ 'Load', 'Status', 'Charge', 'Carrier Cost', 'ZIP code (Shipper address)' ])) }

    context 'with headers' do
      let(:headers) { { 'shipper_address.zip_code' => 'Origin ZIP Code', status: 'State' } }

      it { is_expected.to(eq([ 'Load', 'State', 'Charge', 'Carrier Cost', 'Origin ZIP Code' ])) }
    end
  end

  describe '#rows' do
    subject { exporter.rows }

    it { is_expected.to(eq([ row ])) }

    context 'when a value is blank' do
      let(:columns) { [ 'pro' ] }
      let(:shipment) { create(:shipment, pro: nil) }

      it { is_expected.to(eq([ [ nil ] ])) }
    end

    context 'when a column is a phone number' do
      let(:authorizable) { create(:broker_user, companyable: contact.companyable) }
      let(:columns) { [ 'work_phone' ] }
      let(:contact) { create(:contact, companyable: create(:broker), work_phone:) }
      let(:records) { Contact.where(id: contact.id) }
      let(:work_phone) { '(555) 123-4567' }

      it { is_expected.to(eq([ [ '+15551234567' ] ])) }

      context 'when international' do
        let(:work_phone) { '+44 20 7946 0958' }

        it { is_expected.to(eq([ [ '+442079460958' ] ])) }
      end
    end

    context 'with every available column', :bullet do
      let(:columns) { described_class.available_columns(Shipment, authorizable) }
      let(:records) { Shipment.where(broker: shipment.broker) }

      before { create_list(:shipment, 2, :with_broker_accessorials, :with_items, broker: shipment.broker, broker_carrier:) }

      it { expect { exporter.rows }.not_to(raise_error) }
    end
  end

  describe '#updated_at' do
    subject { exporter.updated_at }

    let(:shipment) { create(:shipment, shipper_address: create(:address, updated_at: 1.day.from_now)) }

    it { is_expected.to(be_within(1.second).of(shipment.shipper_address.updated_at)) }

    context 'with distinct, ordered records' do
      let(:records) { Shipment.where(id: shipment.id).distinct.order(:created_at) }

      it { is_expected.to(be_within(1.second).of(shipment.shipper_address.updated_at)) }
    end
  end

  describe '#to_csv' do
    subject { CSV.parse(exporter.to_csv) }

    it { is_expected.to(eq([ exporter.headers, row.map(&:to_s) ])) }
    it { expect(exporter.to_csv).to(start_with('"Load","Status"')) }

    context 'with a formula-like value' do
      let(:columns) { [ 'load_id', 'shipper_name' ] }
      let(:shipment) { create(:shipment, shipper_name: '=Hyperlink("https://example.com")') }

      it { is_expected.to(eq([ exporter.headers, [ shipment.load_id.to_s, %('=Hyperlink("https://example.com")) ] ])) }
      it { expect(exporter.rows).to(eq([ [ shipment.load_id, '=Hyperlink("https://example.com")' ] ])) }
    end
  end

  describe '#to_json' do
    it { expect(JSON.parse(exporter.to_json)).to(eq(JSON.parse(exporter.data.to_json))) }
  end

  describe '#to_yaml' do
    it { expect(YAML.unsafe_load(exporter.to_yaml)).to(eq(exporter.data)) }
  end
end
