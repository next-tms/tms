require 'rails_helper'

RSpec.describe(Resolvers::InvoicesResolver) do
  subject(:result) { TMSSchema.execute(query, context: { authorizable: }, variables:).to_h }

  let(:authorizable) { create(:customer_user, companyable: receivables.first.shipment.broker_customer) }
  let(:items) { result.dig('data', 'invoices', 'items') }
  let(:query) do
    <<~GRAPHQL
      query($filter: InvoiceFilter) {
        invoices(filter: $filter) {
          items { balanceCents dueOn id issuedOn number paidAt shipment { loadId } totalCents totalCurrency }
          totalItems
        }
      }
    GRAPHQL
  end
  let!(:receivables) { [create(:receivable, total_cents: 1_000), create(:receivable, total_cents: 2_000)] }
  let(:variables) { {} }

  before { create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles') }

  describe '#resolve' do
    it { expect(items.pluck('id')).to(eq([receivables.first.id.to_s])) }
    it { expect(items.first['number']).to(eq(receivables.first.shipment.load_id.to_s)) }
    it { expect(items.first['shipment']).to(eq('loadId' => receivables.first.shipment.load_id)) }
    it { expect(items.first['totalCents']).to(eq(1_000)) }

    it do
      expect(items.first.slice('dueOn', 'issuedOn')).to(
        eq(
          'dueOn' => receivables.first.due_by.in_time_zone(Setting.time_zone).to_date.iso8601,
          'issuedOn' => receivables.first.authorized_at.in_time_zone(Setting.time_zone).to_date.iso8601
        )
      )
    end

    context 'with an accounts receivable user' do
      let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:accounts_receivable) } }

      it { expect(result.dig('data', 'invoices', 'totalItems')).to(eq(2)) }

      context 'with a filter' do
        let(:variables) { { filter: { shipmentIdEq: receivables.last.shipment_id } } }

        it { expect(items.pluck('id')).to(eq([receivables.last.id.to_s])) }
      end
    end

    context 'with a carrier user' do
      let(:authorizable) { create(:carrier_user) }

      it { expect(items).to(be_empty) }
    end
  end

  describe 'filter type' do
    it { expect(GraphQL::Query.new(TMSSchema, context: { authorizable: }).types.type('InvoiceFilter')).to(be(Types::InvoiceFilterType)) }
  end
end
