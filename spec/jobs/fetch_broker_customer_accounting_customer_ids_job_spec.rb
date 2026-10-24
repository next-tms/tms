require 'rails_helper'

RSpec.describe(FetchBrokerCustomerAccountingCustomerIdsJob) do
  describe '#perform' do
    let(:broker_customer) { create(:broker_customer, accounting_customer_id: nil) }
    let(:relation) { instance_double(ActiveRecord::Relation, find_each: [ broker_customer ].each) }

    before do
      allow(Accounting).to(receive(:connected?).and_return(true))
      allow(AccountingMailer).to(receive(:unknown_customers).and_return(instance_double(ActionMailer::MessageDelivery, deliver_now: true)))
      allow(BrokerCustomer).to(receive(:where).and_call_original)
      allow(BrokerCustomer).to(receive(:where).with(accounting_customer_id: nil).and_return(relation))
      allow(relation).to(receive(:includes).with(:customer).and_return(relation))
      allow(broker_customer).to(receive(:accounting_customer))
      described_class.perform_now
    end

    it { expect(broker_customer).to(have_received(:accounting_customer)) }
    it { expect(AccountingMailer).to(have_received(:unknown_customers)) }

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
