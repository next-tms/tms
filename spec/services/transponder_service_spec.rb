require 'rails_helper'

RSpec.describe(TransponderService) do
  let(:broker_carrier) { instance_double(BrokerCarrier) }
  let(:shipment) { instance_double(Shipment) }

  describe '.query' do
    subject { described_class.query(:fetch_rates, broker_carrier, shipment) }

    before do
      allow(described_class::Query).to(receive(:call).and_return({}))
      allow(GraphQLClient::Transponder::Client).to(receive(:query).and_raise(GraphQL::Client::Error, 'HTTP status 500'))
      allow(Sentry).to(receive(:capture_exception))
    end

    it { is_expected.to(eq({ errors: [{ message: 'HTTP status 500' }] })) }
  end
end
