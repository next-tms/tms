require 'rails_helper'

RSpec.describe(ProblematicService::Rule::Shipment::MissingCarrierBOL) do
  describe '#suppressor_instigators' do
    subject(:suppressor_instigators) { described_class.new(nil).with(shipment).suppressor_instigators }

    let(:shipment) { build(:shipment) }
    let!(:setting) { create(:setting, key: 'requires_charges_confirmed_on_receivables', value: true) }

    it { is_expected.to(contain_exactly(setting, shipment.broker_customer)) }

    context 'when shipment.broker_customer is blank' do
      let(:shipment) { build(:shipment, broker_customer: nil) }

      it { is_expected.to(contain_exactly(setting)) }
    end
  end
end
