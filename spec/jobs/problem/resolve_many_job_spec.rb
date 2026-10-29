require 'rails_helper'

RSpec.describe(Problem::ResolveManyJob) do
  describe '#perform' do
    let!(:resolvable_problem) { create(:problem, problematic_rule_code: 'missing_picked_up_at') }
    let!(:resolved_problem) { create(:problem, problematic_rule_code: 'missing_picked_up_at', resolved_at: Time.current) }
    let!(:unresolvable_problem) { create(:problem, problematic_rule_code: 'missing_pro') }

    before { described_class.perform_now }

    it { expect(Problem::ResolveJob).to(have_been_enqueued.with(resolvable_problem)) }
    it { expect(Problem::ResolveJob).not_to(have_been_enqueued.with(resolved_problem)) }
    it { expect(Problem::ResolveJob).not_to(have_been_enqueued.with(unresolvable_problem)) }
  end
end
