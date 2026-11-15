require 'rails_helper'
require Rails.root.join('db/migrate/20261111042359_copy_standardized_addresses_to_addresses')

RSpec.describe(CopyStandardizedAddressesToAddresses) do
  let(:address) { create(:address, latitude: nil, longitude: nil, time_zone_name: nil) }
  let(:address_model) { described_class::Address }
  let(:migration) { described_class.new }
  let(:smarty) { { 'metadata' => { 'rdi' => 'Residential', 'record_type' => 'P' } }.to_yaml }
  let(:spot) { "--- !ruby/object:GooglePlaces::Spot\npermanently_closed: true\ntypes:\n- establishment\n- restaurant\n" }
  let(:standardized_address_model) { described_class::StandardizedAddress }

  before do
    address
    connection = ActiveRecord::Base.connection
    connection.create_table(:standardized_addresses) do |t|
      t.text :google_places_spot_cached
      t.string :latitude
      t.string :longitude
      t.text :smarty_streets_result_cached
      t.string :time_zone_name
    end
    connection.add_column(:addresses, :standardized_address_id, :bigint)
    [address_model, standardized_address_model].each(&:reset_column_information)

    standardized_address = standardized_address_model.create!(
      google_places_spot_cached: spot,
      latitude: '37.5',
      longitude: '-122.0',
      smarty_streets_result_cached: smarty,
      time_zone_name: 'America/Los_Angeles'
    )
    address_model.where(id: address.id).update_all(standardized_address_id: standardized_address.id) # rubocop:disable Rails/SkipsModelValidations

    ActiveRecord::Migration.suppress_messages { migration.up }
  end

  after { [Address, address_model, standardized_address_model].each(&:reset_column_information) }

  describe '#down' do
    it { expect { migration.down }.to(raise_error(ActiveRecord::IrreversibleMigration)) }
  end

  describe '#up' do
    it do
      expect(address_model.find(address.id)).to(
        have_attributes(
          business: false,
          permanently_closed: true,
          po_box: true,
          residential: true,
          time_zone_name: 'America/Los_Angeles',
          types: ['restaurant']
        )
      )
    end

    it { expect(address_model.find(address.id).latitude.to_f).to(eq(37.5)) }

    context 'when the caches are empty' do
      let(:smarty) { nil }
      let(:spot) { nil }

      it { expect(address_model.find(address.id)).to(have_attributes(business: nil, permanently_closed: nil, residential: nil, types: [])) }
    end
  end
end
