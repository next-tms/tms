require 'rails_helper'

RSpec.describe(Types::QueryType) do
  subject(:result) { LiftoffSchema.execute(query, context: { authorizable: }, variables: { id: }).to_h }

  let(:authorizable) { create(:broker_user) }
  let(:customer) { create(:broker_customer) }
  let(:id) { customer.id }
  let(:query) { 'query($id: ID!) { customer(id: $id) { id name } }' }

  describe '#shipment' do
    let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:dispatch) } }
    let(:id) { shipment.load_id }
    let(:query) { 'query($id: ID!) { shipment(id: $id) { id loadId } }' }
    let(:shipment) { create(:shipment) }

    it { expect(result.dig('data', 'shipment')).to(eq('id' => shipment.load_id.to_s, 'loadId' => shipment.load_id)) }

    context 'when given the database id' do
      let(:id) { shipment.id }
      let(:shipment) { create(:shipment, load_id: create(:shipment).load_id + 1000) }

      it { expect(result.dig('data', 'shipment')).to(be_nil) }
    end
  end

  describe 'fields' do
    it { expect(described_class.fields.keys).not_to(include('brokerCarrier', 'brokerCarriers', 'brokerCustomer', 'brokerCustomers')) }
    it { expect(described_class.fields.keys).to(include('carrier', 'carriers', 'customer', 'customers', 'shipment', 'shipments')) }
    it { expect(described_class.fields.keys).to(include('task', 'tasks')) }
    it { expect(described_class.fields['shipments'].resolver).to(eq(Resolvers::ShipmentsResolver)) }
    it { expect(described_class.fields['tasks'].resolver).to(eq(Resolvers::TasksResolver)) }
  end

  describe 'singular fields' do
    it { expect(result.dig('data', 'customer')).to(eq('id' => customer.id.to_s, 'name' => customer.customer.name)) }

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
