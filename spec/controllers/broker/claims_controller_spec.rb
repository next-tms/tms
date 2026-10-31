require 'rails_helper'

RSpec.describe(Broker::ClaimsController) do
  describe '#claim_params' do
    subject { controller.__send__(:claim_params).to_h }

    let(:attributes) { { claim_items_attributes: { '0' => { total: '50' } }, due_on: '2026-11-01' } }

    before { controller.params = { claim: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end
end
