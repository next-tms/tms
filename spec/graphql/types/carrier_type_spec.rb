require 'rails_helper'

RSpec.describe(Types::CarrierType) do
  subject(:data) { TMSSchema.execute(query, context:, variables: { id: carrier.id }).to_h.dig('data', 'carrier') }

  let!(:broker_carrier) { create(:broker_carrier, carrier:) }
  let(:carrier) { create(:carrier, legal_name: 'Acme Freight LLC', name: 'Acme') }
  let(:context) { { authorizable: create(:broker_user) } }
  let(:query) { 'query($id: ID!) { carrier(id: $id) { accounts { items { id } } legalName name } }' }

  before { create(:broker_carrier) }

  it { expect(data['accounts']).to(eq('items' => [{ 'id' => broker_carrier.id.to_s }])) }
  it { expect(data['legalName']).to(eq('Acme Freight LLC')) }
  it { expect(data['name']).to(eq('Acme')) }
end
