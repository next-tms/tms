# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Shipment::ResetRatesService) do
  let(:shipment) { create(:shipment) }
  let!(:rate) { create(:rate, shipment: shipment, shipment_fingerprint: '123') }
  let!(:other_rate) { create(:rate, shipment: shipment) }

  describe '#call' do
    context 'when force_reset params is true' do
      subject { described_class.new(shipment, force_reset: true).call }

      context 'and shipment#applied_rate is blank?' do
        it 'destroy rates' do
          expect { subject }.to(change(Rate, :count).from(2).to(0))
        end
      end

      context 'and shipment#applied_rate is present' do
        before { shipment.update(applied_rate: other_rate) }

        it 'destroy rates except applied rate' do
          expect { subject }.to(change(Rate, :count).from(2).to(1))

          expect(other_rate).to(be_persisted)
        end
      end
    end

    context 'when force_reset params if false' do
      subject { described_class.new(shipment).call }

      context "and shipment first rate's fingerprint is equal to shipment#fingerprint " do
        it 'does not destroy rates' do
          expect(shipment).to(receive(:fingerprint).and_return(rate.shipment_fingerprint))

          expect { subject }.not_to(change(Rate, :count))
        end
      end

      context 'and shipment#calculated_freight_classes and shipment#declared_freight_classes are blank ' do
        it 'does not destroy rates' do
          expect(shipment).to(receive(:fingerprint).and_return('Other Fingerprint'))
          expect(shipment).to(receive(:calculated_freight_classes).and_return([nil]))
          expect(shipment).to(receive(:declared_freight_classes).and_return([]))

          expect { subject }.not_to(change(Rate, :count))
        end
      end

      context 'and rates are destroyable' do
        context 'and shipment#applied_rate is blank?' do
          before do
            expect(shipment).to(receive(:fingerprint).and_return('Other Fingerprint'))
          end

          it 'destroy rates' do
            expect { subject }.to(change(Rate, :count).from(2).to(0))
          end
        end

        context 'and shipment#applied_rate is present' do
          before do
            shipment.update(applied_rate: other_rate)
            expect(shipment).to(receive(:fingerprint).and_return('Other Fingerprint'))
          end

          it 'destroy rates except applied rate' do
            expect { subject }.to(change(Rate, :count).from(2).to(1))

            expect(other_rate).to(be_persisted)
          end
        end
      end
    end
  end
end
