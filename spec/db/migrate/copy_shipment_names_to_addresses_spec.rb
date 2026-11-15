require 'rails_helper'
require Rails.root.join('db/migrate/20261111073201_copy_shipment_names_to_addresses')

RSpec.describe(CopyShipmentNamesToAddresses) do
  let(:address_model) { described_class::Address }
  let(:migration) { described_class.new }
  let(:receiver_address) { create(:address, name: 'Kept') }
  let(:shipment_model) { described_class::Shipment }
  let(:shipper_address) { create(:address, name: nil) }

  let!(:shipment) { shipment_model.find(create(:shipment, receiver_address:, shipper_address:).id) }

  before do
    ActiveRecord::Migration.suppress_messages do
      migration.add_column(:shipments, :receiver_name, :string)
      migration.add_column(:shipments, :shipper_name, :string)
    end
    shipment_model.reset_column_information
  end

  after { shipment_model.reset_column_information }

  describe '#down' do
    before do
      shipper_address.update!(name: 'Shipper Co')
      ActiveRecord::Migration.suppress_messages { migration.down }
    end

    it { expect(shipment.reload).to(have_attributes(receiver_name: 'Kept', shipper_name: 'Shipper Co')) }
  end

  describe '#up' do
    let(:receiver_name) { 'Receiver Co' }
    let(:shipper_name) { 'Shipper Co' }

    before do
      shipment.reload.update!(receiver_name:, shipper_name:)
      ActiveRecord::Migration.suppress_messages { migration.up }
    end

    it { expect(address_model.find(receiver_address.id).name).to(eq('Receiver Co')) }
    it { expect(address_model.find(shipper_address.id).name).to(eq('Shipper Co')) }

    context 'when a name is blank' do
      let(:receiver_name) { '' }

      it { expect(address_model.find(receiver_address.id).name).to(eq('Kept')) }
    end

    context 'when both roles share an address with different names' do
      let(:receiver_address) { shipper_address }

      it { expect(address_model.find(shipper_address.id).name).to(eq('Receiver Co')) }
      it { expect(shipment.reload.shipper_address_id).not_to(eq(shipper_address.id)) }
      it { expect(address_model.find(shipment.reload.shipper_address_id).name).to(eq('Shipper Co')) }
    end

    context 'when both roles share an address with the same name' do
      let(:receiver_address) { shipper_address }
      let(:receiver_name) { 'Shipper Co' }

      it { expect(shipment.reload.shipper_address_id).not_to(eq(shipper_address.id)) }
    end

    context 'when a later role sharing a renamed address has no name' do
      let(:receiver_address) { shipper_address }
      let(:shipper_name) { nil }

      it { expect(address_model.find(shipper_address.id).name).to(eq('Receiver Co')) }
      it { expect(address_model.find(shipment.reload.shipper_address_id).name).to(be_nil) }
    end

    context 'when a customer owns the address' do
      let(:shipper_address) { create(:broker_customer, primary_pickup_address: create(:address, name: 'Pickup')).primary_pickup_address }

      it { expect(address_model.find(shipper_address.id).name).to(eq('Pickup')) }
      it { expect(address_model.find(shipment.reload.shipper_address_id).name).to(eq('Shipper Co')) }
    end
  end
end
