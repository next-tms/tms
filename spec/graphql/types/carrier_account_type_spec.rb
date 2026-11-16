require 'rails_helper'

RSpec.describe(Types::CarrierAccountType) do
  subject(:data) { result.dig('data', 'carrier', 'accounts', 'items', 0) }

  let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:dispatch) } }
  let(:broker_carrier) { create(:broker_carrier, broker_customer: create(:broker_customer)) }
  let(:errors) { result['errors'].pluck('message') }
  let(:fields) { 'carrier { id } customer { id } shipments { items { id } totalItems }' }
  let(:query) { "query($id: ID!) { carrier(id: $id) { accounts { items { #{fields} } } } }" }
  let(:result) { LiftoffSchema.execute(query, context: { authorizable: }, variables: { id: broker_carrier.carrier_id }).to_h }
  let!(:shipment) { create(:shipment, broker_carrier:) }

  before { create(:shipment, broker_carrier: create(:broker_carrier)) }

  it { expect(data['carrier']).to(eq('id' => broker_carrier.carrier_id.to_s)) }
  it { expect(data['customer']).to(eq('id' => broker_carrier.broker_customer_id.to_s)) }
  it { expect(data['shipments']).to(eq('items' => [{ 'id' => shipment.load_id.to_s }], 'totalItems' => 1)) }

  describe '.policy_class' do
    it { expect(described_class.policy_class).to(eq(BrokerCarrierPolicy)) }
  end

  describe 'markup fields' do
    let(:fields) { 'quotePaddingCents quotePaddingCurrency' }

    it { expect(data.values).to(all(be_present)) }

    context 'when the user is a carrier' do
      let(:authorizable) { create(:user, companyable: broker_carrier.carrier) }

      it { expect(errors).to(include("Field 'quotePaddingCents' doesn't exist on type 'CarrierAccount'")) }
    end
  end

  describe 'note fields' do
    let(:fields) { 'accountingNotes' }

    before { broker_carrier.update!(accounting_notes: 'Slow payer') }

    it { expect(data).to(eq('accountingNotes' => 'Slow payer')) }

    context 'when the user is a carrier' do
      let(:authorizable) { create(:user, companyable: broker_carrier.carrier) }

      it { expect(errors).to(include("Field 'accountingNotes' doesn't exist on type 'CarrierAccount'")) }
    end
  end
end
