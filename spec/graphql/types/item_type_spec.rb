require 'rails_helper'

RSpec.describe(Types::ItemType) do
  subject(:data) { result.dig('data', 'shipment', 'items') }

  let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:dispatch) } }
  let(:expected) do
    {
      'declaredFreightClass' => 70.0,
      'description' => 'Widgets',
      'height' => 40,
      'id' => item.id.to_s,
      'length' => 48,
      'packaging' => 'pallet',
      'quantity' => 2,
      'weight' => 500,
      'width' => 42
    }
  end
  let(:fields) { 'declaredFreightClass description height id length packaging quantity weight width' }
  let!(:item) do
    create(:item, declared_freight_class: 70, desc: 'Widgets', h: 40, l: 48, packaging:, quantity: 2, shipment:, w: 42, weight: 500)
  end
  let(:packaging) { create(:packaging, freight_kit_type: 'pallet') }
  let(:query) { "query($id: ID!) { shipment(id: $id) { items { #{fields} } } }" }
  let(:result) { LiftoffSchema.execute(query, context: { authorizable: }, variables: { id: shipment.load_id }).to_h }
  let(:shipment) { create(:shipment) }

  it { is_expected.to(eq([expected])) }

  describe '#packaging' do
    let(:fields) { 'packaging' }

    before { item.update_column(:packaging_id, nil) } # rubocop:disable Rails/SkipsModelValidations

    it { is_expected.to(eq([{ 'packaging' => nil }])) }
  end
end
