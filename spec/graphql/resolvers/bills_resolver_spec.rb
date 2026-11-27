require 'rails_helper'

RSpec.describe(Resolvers::BillsResolver) do
  subject(:result) { TMSSchema.execute(query, context: { authorizable: }, variables:).to_h }

  let(:authorizable) { create(:user, companyable: broker_carrier.carrier) }
  let(:broker_carrier) { create(:broker_carrier) }
  let(:items) { result.dig('data', 'bills', 'items') }
  let!(:payment_transactions) do
    [
      create(:payment_transaction, balance_cents: 1_000, broker_carrier:, invoice: 'INV-1', pro: 'PRO-1', shipment:),
      create(:payment_transaction, balance_cents: 2_000, invoice: 'INV-2')
    ]
  end
  let(:query) do
    <<~GRAPHQL
      query($filter: BillFilter) {
        bills(filter: $filter) {
          items { balanceCents dueOn id invoiceNumber number paidCents pro shipment { loadId } }
          totalItems
        }
      }
    GRAPHQL
  end
  let(:shipment) { create(:shipment, broker_carrier:, carrier_cost_currency: 'USD') }
  let(:variables) { {} }

  describe '#resolve' do
    it { expect(items.pluck('id')).to(eq([payment_transactions.first.id.to_s])) }
    it { expect(items.first).to(include('balanceCents' => 1_000, 'invoiceNumber' => 'INV-1', 'pro' => 'PRO-1')) }
    it { expect(items.first['dueOn']).to(eq(payment_transactions.first.due_on.iso8601)) }
    it { expect(items.first['number']).to(eq(payment_transactions.first.shipment.load_id.to_s)) }

    context 'with an accounts payable user' do
      let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:accounts_payable) } }

      it { expect(result.dig('data', 'bills', 'totalItems')).to(eq(2)) }

      context 'with a filter' do
        let(:variables) { { filter: { invoiceEq: 'INV-2' } } }

        it { expect(items.pluck('id')).to(eq([payment_transactions.last.id.to_s])) }
      end
    end

    context 'with a customer user' do
      let(:authorizable) { create(:customer_user, companyable: payment_transactions.first.shipment.broker_customer) }

      it { expect(items).to(be_empty) }
    end
  end

  describe 'filter type' do
    it { expect(GraphQL::Query.new(TMSSchema, context: { authorizable: }).types.type('BillFilter')).to(be(Types::BillFilterType)) }
  end
end
