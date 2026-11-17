require 'rails_helper'

RSpec.describe(Tools::FilterSummary) do
  let(:profile) { Tools::BaseTool.profile_for(authorizable: create(:root_broker_user)) }

  describe '.call' do
    subject { described_class.call(Types::ShipmentFilterType, profile) }

    let(:string_predicates) { Types::Concerns::Filterable::PREDICATES[:string].keys.sort.join(', ') }

    it { is_expected.to(start_with('input ShipmentFilter: keys join an attribute and a predicate')) }
    it { is_expected.to(include("  String: #{string_predicates}\n")) }

    it { is_expected.to(match(/^  Int: .*\bload_id\b/)) }
    it { is_expected.to(match(/^  ISO8601Date: .*\bpickup_on\b/)) }
  end

  describe '.predicate' do
    subject { described_class.predicate(Types::ShipmentFilterType.arguments.fetch(name)) }

    let(:name) { 'loadIdNotIn' }

    it { is_expected.to(eq(['load_id', 'not_in', 'Int'])) }

    context 'with the or argument' do
      let(:name) { 'or' }

      it { is_expected.to(be_nil) }
    end

    context 'with a case-insensitive predicate' do
      let(:name) { 'bolNotICont' }

      it { is_expected.to(eq(['bol', 'not_i_cont', 'String'])) }
    end
  end
end
