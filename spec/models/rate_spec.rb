# == Schema Information
#
# Table name: rates
#
# @!attribute id
#   @return []
# @!attribute api_errors
#   @return [Hash]
# @!attribute api_request
#   @return [String]
# @!attribute api_response
#   @return [String]
# @!attribute breakdown
#   @return [Hash]
# @!attribute cost_cents
#   @return [Integer]
# @!attribute cost_currency
#   @return [String]
# @!attribute declared_freight_classes
#   @return [Boolean]
# @!attribute expires_at
#   @return [Time]
# @!attribute freight_kit_service_type
#   @return [String]
# @!attribute incomplete
#   @return [Boolean]
# @!attribute reference
#   @return [String]
# @!attribute shipment_fingerprint
#   @return [String]
# @!attribute source
#   @return [String]
# @!attribute transit_days
#   @return [Integer]
# @!attribute uid
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_carrier_id
#   @return []
# @!attribute broker_customer_id
#   @return []
# @!attribute shipment_id
#   @return []
# @!attribute tracking_carrier_id
#   @return []
#
# Indexes
#
#  index_rates_on_broker_carrier_id         (broker_carrier_id)
#  index_rates_on_broker_customer_id        (broker_customer_id)
#  index_rates_on_freight_kit_service_type  (freight_kit_service_type)
#  index_rates_on_shipment_id               (shipment_id)
#  index_rates_on_tracking_carrier_id       (tracking_carrier_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (tracking_carrier_id => carriers.id)
#
require 'rails_helper'

RSpec.describe(Rate) do
  describe '#charge' do
    subject(:charge) { rate.charge }

    let(:rate) { build(:rate, cost_cents: 10_000, cost_currency: 'USD', shipment:) }

    context 'with a broker customer' do
      let(:shipment) { build(:shipment) }

      before { allow(shipment.broker_customer).to(receive(:carrier_charge_calculator).and_return(Money.new(12_000, 'USD'))) }

      it { is_expected.to(eq(Money.new(12_000, 'USD'))) }

      it do
        2.times { rate.charge }

        expect(shipment.broker_customer).to(have_received(:carrier_charge_calculator).with(carrier_cost: rate.cost, shipment:).once)
      end
    end

    context 'without a broker customer' do
      let(:shipment) { build(:shipment, broker_customer: nil) }

      it { is_expected.to(be_nil) }
    end
  end

  describe '#preferred?' do
    subject { rate.preferred? }

    let(:broker_carrier) { create(:broker_carrier) }
    let(:broker_customer) { create(:broker_customer, preferred_broker_carriers_kind: 'blacklist') }
    let(:rate) { build(:rate, broker_carrier:, broker_customer:, shipment: build(:shipment, broker_customer:)) }

    context 'when the broker carrier is blacklisted' do
      before { broker_customer.preferred_broker_carriers.create!(broker_carrier:) }

      it { is_expected.to(be(false)) }
    end

    context 'when the broker carrier is not blacklisted' do
      it { is_expected.to(be(true)) }
    end

    context 'with the customer user type' do
      before { allow(broker_customer).to(receive(:eligible_broker_carriers).and_call_original) }

      it do
        rate.preferred?

        expect(broker_customer).to(have_received(:eligible_broker_carriers).with(:customer))
      end
    end

    context 'without a broker customer' do
      let(:rate) { build(:rate, broker_carrier:, broker_customer: nil) }

      it { is_expected.to(be(true)) }
    end
  end
end
