require 'rails_helper'

RSpec.describe(Resolvers::CarriersResolver) do
  subject(:result) { LiftoffSchema.execute(query, context: { authorizable: }).to_h }

  let(:authorizable) { create(:broker_user) }
  let(:ids) { result.dig('data', 'carriers', 'items').pluck('id') }
  let!(:matching_record) { create(:carrier, scac: 'ABCD') }
  let!(:other_record) { create(:carrier, scac: 'WXYZ') }
  let(:query) { '{ carriers(filter: { scacEq: "ABCD" }) { items { id } totalItems } }' }

  it_behaves_like('filterable GraphQL resolver')

  describe '#resolve' do
    it { expect(ids).to(eq([matching_record.id.to_s])) }

    context 'when the user is not a broker' do
      let(:authorizable) { create(:customer_user) }

      it { expect(ids).to(be_empty) }
    end
  end
end
