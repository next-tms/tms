require 'rails_helper'

RSpec.describe(Types::BrokerCustomerType) do
  subject(:data) { result.dig('data', 'brokerCustomer') }

  let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:dispatch) } }
  let(:broker_carrier) { create(:broker_carrier, broker_customer:) }
  let(:broker_customer) { create(:broker_customer) }
  let(:errors) { result['errors'].pluck('message') }

  let(:query) do
    <<~GRAPHQL
      query($id: ID!) {
        brokerCustomer(id: $id) {
          brokerCarriers { items { id } }
          customer { id }
          officeAddress { id }
          primaryPickupAddress { id }
          shipments(filter: { shipperNameEq: "Acme" }) { items { id } }
        }
      }
    GRAPHQL
  end

  let(:result) { LiftoffSchema.execute(query, context: { authorizable: }, variables: { id: broker_customer.id }).to_h }

  let!(:shipment) { create(:shipment, broker_carrier:, broker_customer:, shipper_name: 'Acme') }

  before { create(:shipment, broker_carrier:, shipper_name: 'Acme') }

  it { expect(data['brokerCarriers']).to(eq('items' => [{ 'id' => broker_carrier.id.to_s }])) }
  it { expect(data['customer']).to(eq('id' => broker_customer.customer_id.to_s)) }
  it { expect(data['officeAddress']).to(eq('id' => broker_customer.office_address_id.to_s)) }
  it { expect(data['primaryPickupAddress']).to(eq('id' => broker_customer.primary_pickup_address_id.to_s)) }
  it { expect(data['shipments']).to(eq('items' => [{ 'id' => shipment.id.to_s }])) }

  describe 'markup fields' do
    let(:query) { 'query($id: ID!) { brokerCustomer(id: $id) { defaultUpchargeCents defaultUpchargeCurrency defaultUpchargePercentage } }' }

    before { broker_customer.update!(default_upcharge_cents: 500, default_upcharge_percentage: 10) }

    it { expect(data.values).to(all(be_present)) }

    context 'when the user is a customer' do
      let(:authorizable) { create(:customer_user, companyable: broker_customer) }

      it { expect(errors).to(include("Field 'defaultUpchargeCents' doesn't exist on type 'BrokerCustomer'")) }
    end
  end

  describe 'note fields' do
    let(:query) { 'query($id: ID!) { brokerCustomer(id: $id) { internalNotes } }' }

    before { broker_customer.update!(internal_notes: 'Credit hold') }

    it { expect(data).to(eq('internalNotes' => 'Credit hold')) }

    context 'when the user is a customer' do
      let(:authorizable) { create(:customer_user, companyable: broker_customer) }

      it { expect(errors).to(include("Field 'internalNotes' doesn't exist on type 'BrokerCustomer'")) }
    end
  end
end
