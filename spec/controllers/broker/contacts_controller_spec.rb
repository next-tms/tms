require 'rails_helper'

RSpec.describe(Broker::ContactsController) do
  describe '#contact_params' do
    subject { controller.__send__(:contact_params).to_h }

    let(:attributes) { { email: 'ada@example.com', first_name: 'Ada' } }

    before { controller.params = { contact: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end
end
