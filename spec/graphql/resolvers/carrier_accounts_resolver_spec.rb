require 'rails_helper'

RSpec.describe(Resolvers::CarrierAccountsResolver) do
  subject(:result) { LiftoffSchema.execute(query, context: { authorizable: }, variables: { id: customer.id }).to_h }

  let(:authorizable) { create(:broker_user) }
  let(:customer) { create(:broker_customer) }
  let(:ids) { result.dig('data', 'customer', 'carrierAccounts', 'items').pluck('id') }
  let!(:matching_record) { create(:broker_carrier, broker_customer: customer, carrier: create(:carrier, scac: 'ABCD')) }
  let!(:other_record) { create(:broker_carrier, broker_customer: customer, carrier: create(:carrier, scac: 'WXYZ')) }
  let(:query) { 'query($id: ID!) { customer(id: $id) { carrierAccounts(filter: { carrierScacEq: "ABCD" }) { items { id } totalItems } } }' }

  it_behaves_like('filterable GraphQL resolver')

  describe '#resolve' do
    it { expect(ids).to(eq([matching_record.id.to_s])) }

    context 'when the user is a carrier' do
      let(:authorizable) { create(:user, companyable: other_record.carrier) }

      it { expect(result.dig('data', 'customer')).to(be_nil) }
    end
  end
end
