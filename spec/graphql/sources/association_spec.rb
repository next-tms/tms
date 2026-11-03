require 'rails_helper'

RSpec.describe(Sources::Association) do
  describe '#initialize' do
    it { expect { described_class.new(Shipment, :unknown) }.to(raise_error(ArgumentError, "Association 'unknown' not found on Shipment")) }
  end

  describe '#fetch' do
    subject(:fetched) { described_class.new(BrokerCarrier, :carrier).fetch(broker_carriers.map { |record| BrokerCarrier.find(record.id) }) }

    let(:broker_carriers) { create_list(:broker_carrier, 2) }
    let(:queries) { [] }

    it { is_expected.to(eq(broker_carriers.map(&:carrier))) }

    it do
      broker_carriers
      callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?('FROM "carriers"') }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { fetched }

      expect(queries.size).to(eq(1))
    end
  end
end
