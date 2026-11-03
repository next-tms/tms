require 'rails_helper'

RSpec.describe(Types::CarrierType) do
  subject(:data) { LiftoffSchema.execute(query, context:, variables: { id: carrier.id }).to_h.dig('data', 'carrier') }

  let!(:broker_carrier) { create(:broker_carrier, carrier:) }
  let(:carrier) { create(:carrier) }
  let(:context) { { authorizable: create(:broker_user) } }
  let(:query) { 'query($id: ID!) { carrier(id: $id) { brokerCarriers { items { id } } } }' }

  before { create(:broker_carrier) }

  it { expect(data['brokerCarriers']).to(eq('items' => [{ 'id' => broker_carrier.id.to_s }])) }
end
