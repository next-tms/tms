require 'rails_helper'

RSpec.describe(Resolvers::TasksResolver) do
  subject(:result) { TMSSchema.execute(query, context: { authorizable: }, variables:).to_h }

  let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:dispatch) } }
  let(:items) { result.dig('data', 'tasks', 'items') }
  let!(:problems) do
    [
      create(:problem, problematic_rule_code: 'lost'),
      create(:problem, problematic_rule_code: 'missing_carrier_pod', resolved_at: Time.current)
    ]
  end
  let(:query) do
    <<~GRAPHQL
      query($filter: TaskFilter) {
        tasks(filter: $filter) {
          items { assignedTo { id } code id resolved resolvedAt shipment { loadId } title }
          totalItems
        }
      }
    GRAPHQL
  end
  let(:variables) { { filter: { idIn: problems.map(&:id) } } }

  describe '#resolve' do
    it { expect(items.pluck('id')).to(eq(problems.map { |problem| problem.id.to_s })) }
    it { expect(items.first).to(include('code' => 'lost', 'resolved' => false, 'resolvedAt' => nil)) }
    it { expect(items.first['title']).to(eq(problems.first.reload.title)) }
    it { expect(items.first['shipment']).to(eq('loadId' => problems.first.resolvable.load_id)) }
    it { expect(items.first['assignedTo']).to(eq('id' => problems.first.assigned_to_id.to_s)) }
    it { expect(items.last['resolved']).to(be(true)) }

    context 'with a filter' do
      let(:variables) { { filter: { idIn: problems.map(&:id), resolvedAtNull: true } } }

      it { expect(items.pluck('id')).to(eq([problems.first.id.to_s])) }
    end

    context 'with an accounts receivable user' do
      let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:accounts_receivable) } }

      it { expect(items.pluck('id')).to(eq([problems.last.id.to_s])) }
    end

    context 'with a customer user' do
      let(:authorizable) { create(:customer_user) }

      it { expect(items).to(be_empty) }
    end
  end

  describe 'filter type' do
    it { expect(GraphQL::Query.new(TMSSchema, context: { authorizable: }).types.type('TaskFilter')).to(be(Types::TaskFilterType)) }
  end
end
