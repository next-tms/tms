require 'rails_helper'

RSpec.describe(Resolvers::BrokerCarriersResolver) do
  subject(:result) { LiftoffSchema.execute(query, context: { authorizable: }).to_h }

  let(:authorizable) { create(:broker_user) }
  let(:ids) { result.dig('data', 'brokerCarriers', 'items').pluck('id') }
  let!(:matching_record) { create(:broker_carrier, carrier: create(:carrier, scac: 'ABCD')) }
  let!(:other_record) { create(:broker_carrier, carrier: create(:carrier, scac: 'WXYZ')) }
  let(:query) { '{ brokerCarriers(filter: { carrierScacEq: "ABCD" }) { items { id } totalItems } }' }

  it_behaves_like('filterable GraphQL resolver')

  describe '#resolve' do
    it { expect(ids).to(eq([matching_record.id.to_s])) }

    context 'when the user is not a broker' do
      let(:authorizable) { create(:customer_user) }

      it { expect(ids).to(be_empty) }
    end
  end
end
