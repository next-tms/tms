require 'rails_helper'

RSpec.describe(TransponderService::Input::Shipment) do
  describe '#build' do
    subject { described_class.new(shipment, declared_freight_classes: false, **options).build }

    let(:shipment) { create(:shipment) }

    before { allow(TransponderService::Input::Location).to(receive(:call)) }

    context 'when estimate_reference is blank' do
      let(:options) { { estimate_reference: '' } }

      it { is_expected.to(include(estimate_reference: nil)) }
    end

    context 'when estimate_reference is omitted' do
      let(:options) { {} }

      it { is_expected.to(include(estimate_reference: nil)) }
    end

    context 'when estimate_reference is present' do
      let(:options) { { estimate_reference: 'Q-12345' } }

      it { is_expected.to(include(estimate_reference: 'Q-12345')) }
    end
  end
end
