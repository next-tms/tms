# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Shipment::ResetRatesService) do
  let(:shipment) { create(:shipment) }
  let!(:rate) { create(:rate, shipment:, shipment_fingerprint: '123') }
  let!(:other_rate) { create(:rate, shipment:) }

  describe '#call' do
    context 'when force_reset' do
      subject(:call) { described_class.new(shipment, force_reset: true).call }

      context 'when shipment#applied_rate is blank?' do
        it { expect { call }.to(change(Rate, :count).from(2).to(0)) }
      end

      context 'when shipment#applied_rate is present' do
        before { shipment.update(applied_rate: other_rate) }

        it 'destroys rates except applied rate' do
          expect { call }.to(change(Rate, :count).from(2).to(1))
          expect(other_rate).to(be_persisted)
        end
      end
    end

    context 'when not force_reset' do
      subject(:call) { described_class.new(shipment).call }

      context "when shipment first rate's fingerprint equals shipment#fingerprint" do
        before { allow(shipment).to(receive(:fingerprint).and_return(rate.shipment_fingerprint)) }

        it { expect { call }.not_to(change(Rate, :count)) }
      end

      context 'when shipment#calculated_freight_classes and shipment#declared_freight_classes are blank' do
        before { allow(shipment).to receive_messages(fingerprint: 'Other Fingerprint', calculated_freight_classes: [ nil ], declared_freight_classes: []) }

        it { expect { call }.not_to(change(Rate, :count)) }
      end

      context 'when rates are destroyable' do
        context 'when shipment#applied_rate is blank?' do
          before { allow(shipment).to(receive(:fingerprint).and_return('Other Fingerprint')) }

          it { expect { call }.to(change(Rate, :count).from(2).to(0)) }
        end

        context 'when shipment#applied_rate is present' do
          before do
            shipment.update(applied_rate: other_rate)
            allow(shipment).to(receive(:fingerprint).and_return('Other Fingerprint'))
          end

          it 'destroys rates except applied rate' do
            expect { call }.to(change(Rate, :count).from(2).to(1))
            expect(other_rate).to(be_persisted)
          end
        end
      end
    end
  end
end
