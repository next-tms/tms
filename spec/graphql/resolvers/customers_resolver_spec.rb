require 'rails_helper'

RSpec.describe(Resolvers::CustomersResolver) do
  subject(:result) { TMSSchema.execute(query, context: { authorizable: }).to_h }

  let(:authorizable) { create(:broker_user) }
  let(:ids) { result.dig('data', 'customers', 'items').pluck('id') }
  let!(:matching_record) { create(:broker_customer, customer: create(:customer, name: 'Acme')) }
  let!(:other_record) { create(:broker_customer, customer: create(:customer, name: 'Globex')) }
  let(:query) { '{ customers(filter: { customerNameEq: "Acme" }) { items { id } totalItems } }' }

  it_behaves_like('filterable GraphQL resolver')

  describe '#resolve' do
    it { expect(ids).to(eq([matching_record.id.to_s])) }

    context 'when the user is a customer' do
      let(:authorizable) { create(:customer_user, companyable: other_record) }

      it { expect(ids).to(be_empty) }
    end
  end
end
