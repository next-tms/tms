require 'rails_helper'

RSpec.describe(Broker::PickupsController) do
  describe '#pickup_params' do
    subject { controller.__send__(:pickup_params).to_h }

    let(:attributes) { { rate_uid: 'abc' } }

    before { controller.params = { pickup: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end
end
