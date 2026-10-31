require 'rails_helper'

RSpec.describe(Broker::ProblemsController) do
  describe '#problem_params' do
    subject { controller.__send__(:problem_params).to_h }

    let(:attributes) { { body: 'Truck broke down', title: 'Late' } }

    before { controller.params = { problem: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end
end
