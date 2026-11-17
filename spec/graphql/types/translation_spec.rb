require 'rails_helper'

RSpec.describe(Types::Translation) do
  describe '.call' do
    subject { described_class.call(*keys) }

    let(:keys) { %i[fields query shipments] }

    it { is_expected.to(eq("Search #{Shipment.model_name.human(count: :other)} with optional filters, sorting, and pagination")) }

    context 'with a missing key' do
      let(:keys) { %i[fields query unknown] }

      it { is_expected.to(be_nil) }
    end
  end

  describe '.model_name' do
    subject { described_class.model_name(key) }

    let(:key) { 'broker_customer' }

    it { is_expected.to(eq(BrokerCustomer.model_name.human)) }

    context 'with a plural key' do
      let(:key) { 'broker_customers' }

      it { is_expected.to(eq(BrokerCustomer.model_name.human(count: :other))) }
    end
  end

  describe '.model_names' do
    subject { described_class.model_names('%{shipment}, %{shipments}, %{shipment}') } # rubocop:disable Style/FormatStringToken

    it { is_expected.to(eq(shipment: Shipment.model_name.human, shipments: Shipment.model_name.human(count: :other))) }
  end
end
