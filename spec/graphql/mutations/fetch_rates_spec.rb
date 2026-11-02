require 'rails_helper'

RSpec.describe(Mutations::FetchRates) do
  let(:query) { 'mutation { fetchRates(input: { shipmentLoadId: "0" }) { rates { id } } }' }
  let(:result) { LiftoffSchema.execute(query, context: { current_user: create(:broker_user) }).to_h }

  it { expect(result['errors'].pluck('message')).to(eq(['No Shipment Found'])) }
end
