require 'rails_helper'

RSpec.describe(Broker::DelaysController) do
  describe '#delay_params' do
    subject { controller.__send__(:delay_params).to_h }

    let(:attributes) { { notes: 'Weather' } }

    before { controller.params = { delay: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end
end
