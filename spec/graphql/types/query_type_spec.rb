require 'rails_helper'

RSpec.describe(Types::QueryType) do
  subject(:result) { LiftoffSchema.execute(query, context: { authorizable: }, variables: { id: }).to_h }

  let(:authorizable) { create(:broker_user) }
  let(:customer) { create(:customer) }
  let(:id) { customer.id }
  let(:query) { 'query($id: ID!) { customer(id: $id) { id name } }' }

  describe 'fields' do
    it { expect(described_class.fields.keys).to(include('brokerCarrier', 'brokerCarriers', 'brokerCustomer', 'brokerCustomers')) }
    it { expect(described_class.fields.keys).to(include('carrier', 'carriers', 'customer', 'customers', 'shipment', 'shipments')) }
    it { expect(described_class.fields['shipments'].resolver).to(eq(Resolvers::ShipmentsResolver)) }
  end

  describe 'singular fields' do
    it { expect(result.dig('data', 'customer')).to(eq('id' => customer.id.to_s, 'name' => customer.name)) }

    context 'when the record does not exist' do
      let(:id) { 0 }

      it { expect(result.dig('data', 'customer')).to(be_nil) }
    end

    context 'when the user may not see the record' do
      let(:authorizable) { create(:customer_user) }

      it { expect(result.dig('data', 'customer')).to(be_nil) }
      it { expect(result['errors'].first['extensions']).to(eq('code' => 'UNAUTHORIZED')) }
    end
  end
end
