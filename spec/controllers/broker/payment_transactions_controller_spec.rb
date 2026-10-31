require 'rails_helper'

RSpec.describe(Broker::PaymentTransactionsController) do
  describe '#payment_transaction_params' do
    subject { controller.__send__(:payment_transaction_params).to_h }

    let(:attributes) { { paid: '1', pro: '123' } }

    before { controller.params = { payment_transaction: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end
end
