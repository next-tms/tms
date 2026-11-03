require 'rails_helper'

RSpec.describe(Types::CustomerType) do
  subject(:data) { LiftoffSchema.execute(query, context:, variables: { id: customer.id }).to_h.dig('data', 'customer') }

  let!(:broker_customer) { create(:broker_customer, customer:) }
  let(:context) { { authorizable: create(:broker_user) } }
  let(:customer) { create(:customer) }
  let(:query) { 'query($id: ID!) { customer(id: $id) { brokerCustomers { items { id } } } }' }

  before { create(:broker_customer) }

  it { expect(data['brokerCustomers']).to(eq('items' => [{ 'id' => broker_customer.id.to_s }])) }
end
