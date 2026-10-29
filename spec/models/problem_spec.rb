# == Schema Information
#
# Table name: problems
#
# @!attribute id
#   @return []
# @!attribute body
#   @return [String]
# @!attribute problematic_rule_code
#   @return [String]
# @!attribute resolvable_type
#   @return [String]
# @!attribute resolved_at
#   @return [Time]
# @!attribute suppressions_count
#   @return [Integer]
# @!attribute title
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute assigned_to_id
#   @return []
# @!attribute resolvable_id
#   @return []
# @!attribute resolved_by_id
#   @return []
#
# Indexes
#
#  index_problems_on_assigned_to_id  (assigned_to_id)
#  index_problems_on_body            (body)
#  index_problems_on_resolvable      (resolvable_type,resolvable_id)
#  index_problems_on_resolved_at     (resolved_at)
#  index_problems_on_resolved_by_id  (resolved_by_id)
#  index_problems_on_title           (title)
#
# Foreign Keys
#
#  fk_rails_...  (assigned_to_id => users.id)
#  fk_rails_...  (resolved_by_id => users.id)
#
require 'rails_helper'

RSpec.describe(Problem) do
  describe '#resolve' do
    let(:problem) { build(:problem, problematic_rule_code: 'missing_picked_up_at') }

    before { allow(ProblematicService::Action::Shipment::MissingPickedUpAt).to(receive(:call).and_return(true)) }

    it { expect(problem.resolve).to(be(true)) }
    it { expect(build(:problem, problematic_rule_code: 'missing_pro').resolve).to(be_nil) }

    it do
      problem.resolve
      expect(ProblematicService::Action::Shipment::MissingPickedUpAt).to(have_received(:call).with(problem))
    end
  end

  describe '#resolve?' do
    it { expect(build(:problem, problematic_rule_code: 'missing_picked_up_at').resolve?).to(be(true)) }
    it { expect(build(:problem, problematic_rule_code: 'missing_pro').resolve?).to(be(false)) }
  end

  it_behaves_like 'discussable_topic'
end
