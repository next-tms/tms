require 'rails_helper'

RSpec.describe(Broker::ReceivablesController) do
  describe '#receivable_params' do
    subject { controller.__send__(:receivable_params).to_h }

    let(:attributes) { { invoiced: '1' } }

    before { controller.params = { receivable: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end
end
