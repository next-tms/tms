require 'rails_helper'

RSpec.describe(FetchBrokerCarrierAccountingVendorIdsJob) do
  describe '#perform' do
    let(:broker_carrier) { instance_double(BrokerCarrier, accounting_vendor: nil) }
    let(:relation) { instance_double(ActiveRecord::Relation, find_each: [ broker_carrier ].each) }

    before do
      allow(Accounting).to(receive(:connected?).and_return(true))
      allow(BrokerCarrier).to(receive(:where).with(accounting_vendor_id: nil).and_return(relation))
      allow(relation).to(receive(:includes).with(:carrier).and_return(relation))
      described_class.perform_now
    end

    it { expect(broker_carrier).to(have_received(:accounting_vendor)) }

    context 'when not Accounting.connected?' do
      before { allow(Accounting).to(receive(:connected?).and_return(false)) }

      it { expect(described_class.perform_now).to(be_nil) }
    end
  end

  describe 'legacy Broker arguments' do
    let(:payload) do
      described_class.new.serialize.merge(
        'arguments' => [ { 'broker' => { '_aj_globalid' => "gid://#{GlobalID.app}/Broker/1" }, '_aj_ruby2_keywords' => [ 'broker' ] } ],
      )
    end

    before do
      allow(described_class).to(receive(:perform_later))
      ActiveJob::Base.execute(payload)
    end

    it { expect(described_class).to(have_received(:perform_later).with(no_args)) }
  end
end
