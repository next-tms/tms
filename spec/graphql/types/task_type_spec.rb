require 'rails_helper'

RSpec.describe(Types::TaskType) do
  subject(:task) { result.dig('data', 'task') }

  let(:authorizable) { create(:root_broker_user) }
  let(:problem) { create(:problem, resolved_at: Time.current, resolved_by: authorizable) }
  let(:query) { 'query($id: ID!) { task(id: $id) { id resolvedBy { id } shipment { loadId } } }' }
  let(:result) { LiftoffSchema.execute(query, context: { authorizable: }, variables: { id: problem.id }).to_h }

  describe '.policy_class' do
    it { expect(described_class.policy_class).to(eq(ProblemPolicy)) }
  end

  describe '#resolved_by' do
    it { expect(task['resolvedBy']).to(eq('id' => authorizable.id.to_s)) }
  end

  describe '#shipment' do
    it { expect(task['shipment']).to(eq('loadId' => problem.resolvable.load_id)) }
  end
end
