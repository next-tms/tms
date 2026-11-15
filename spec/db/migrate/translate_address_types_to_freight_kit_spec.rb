require 'rails_helper'
require Rails.root.join('db/migrate/20261111221246_translate_address_types_to_freight_kit')

RSpec.describe(TranslateAddressTypesToFreightKit) do
  let(:address) { create(:address) }
  let(:migration) { described_class.new }

  before { address.update!(types:) }

  describe '#down' do
    let(:types) { ['military_site', 'restaurant', 'storage_facility'] }

    before { ActiveRecord::Migration.suppress_messages { migration.down } }

    it { expect(address.reload[:types]).to(eq(['military', 'restaurant', 'storage'])) }
  end

  describe '#up' do
    let(:types) { ['cafe', 'establishment', 'meal_takeaway', 'military', 'supermarket'] }

    before { ActiveRecord::Migration.suppress_messages { migration.up } }

    it { expect(address.reload[:types]).to(eq(['restaurant', 'military_site', 'grocery_store'])) }
  end
end
