require 'rails_helper'

RSpec.describe(BrokerAccessorial) do
  describe '.blanket' do
    let!(:blanket) { create(:broker_accessorial, accessorial: nil, broker_customer: nil) }

    before { create(:broker_accessorial, accessorial: nil) }

    it { expect(described_class.blanket).to(contain_exactly(blanket)) }
  end
end
