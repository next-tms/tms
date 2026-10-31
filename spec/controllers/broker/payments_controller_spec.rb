require 'rails_helper'

RSpec.describe(Broker::PaymentsController) do
  describe '#payment_params' do
    subject { controller.__send__(:payment_params).to_h }

    let(:attributes) { { method_reference: '1001', payment_transactions_attributes: { '0' => { pro: '123' } } } }

    before { controller.params = { payment: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end
end
