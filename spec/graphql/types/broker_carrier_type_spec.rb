require 'rails_helper'

RSpec.describe(Types::BrokerCarrierType) do
  subject(:data) { result.dig('data', 'brokerCarrier') }

  let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:dispatch) } }
  let(:broker_carrier) { create(:broker_carrier, broker_customer: create(:broker_customer)) }
  let(:errors) { result['errors'].pluck('message') }
  let(:query) do
    'query($id: ID!) { brokerCarrier(id: $id) { brokerCustomer { id } carrier { id } shipments { items { id } totalItems } } }'
  end
  let(:result) { LiftoffSchema.execute(query, context: { authorizable: }, variables: { id: broker_carrier.id }).to_h }
  let!(:shipment) { create(:shipment, broker_carrier:) }

  before { create(:shipment, broker_carrier: create(:broker_carrier)) }

  it { expect(data['brokerCustomer']).to(eq('id' => broker_carrier.broker_customer_id.to_s)) }
  it { expect(data['carrier']).to(eq('id' => broker_carrier.carrier_id.to_s)) }
  it { expect(data['shipments']).to(eq('items' => [{ 'id' => shipment.id.to_s }], 'totalItems' => 1)) }

  describe 'markup fields' do
    let(:query) { 'query($id: ID!) { brokerCarrier(id: $id) { quotePaddingCents quotePaddingCurrency } }' }

    it { expect(data.values).to(all(be_present)) }

    context 'when the user is a carrier' do
      let(:authorizable) { create(:user, companyable: broker_carrier.carrier) }

      it { expect(errors).to(include("Field 'quotePaddingCents' doesn't exist on type 'BrokerCarrier'")) }
    end
  end

  describe 'note fields' do
    let(:query) { 'query($id: ID!) { brokerCarrier(id: $id) { accountingNotes } }' }

    before { broker_carrier.update!(accounting_notes: 'Slow payer') }

    it { expect(data).to(eq('accountingNotes' => 'Slow payer')) }

    context 'when the user is a carrier' do
      let(:authorizable) { create(:user, companyable: broker_carrier.carrier) }

      it { expect(errors).to(include("Field 'accountingNotes' doesn't exist on type 'BrokerCarrier'")) }
    end
  end
end
