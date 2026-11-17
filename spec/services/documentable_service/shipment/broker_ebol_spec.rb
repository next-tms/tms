require 'rails_helper'

RSpec.describe(DocumentableService::Shipment::BrokerEBOL) do
  let(:missing_requirements) { [] }
  let(:service) { described_class.new(shipment) }
  let(:shipment) { create(:shipment) }

  before do
    allow(DocumentableService).to(receive(:call))
    allow(service).to(receive(:missing_requirements).and_return(missing_requirements))
  end

  describe '#check_attributes' do
    subject { service.__send__(:check_attributes) }

    it { is_expected.to(include(:bol, :customer_reference, :value_cents)) }
  end

  describe '#create_missing_document!' do
    before do
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      service.create_missing_document!
    end

    it { expect(DocumentableService::Shipment::CreateBrokerEBOLJob).to(have_been_enqueued.with(shipment)) }

    context 'when the eBOL exists' do
      let(:shipment) do
        create(:shipment).tap do |shipment|
          shipment.broker_ebol.attach(ActiveStorage::Blob.create_and_upload!(filename: 'ebol.json', io: StringIO.new('{}')))
        end
      end

      it { expect(DocumentableService::Shipment::CreateBrokerEBOLJob).not_to(have_been_enqueued) }
    end

    context 'when requirements are missing' do
      let(:missing_requirements) { [:broker_carrier] }

      it { expect(DocumentableService::Shipment::CreateBrokerEBOLJob).not_to(have_been_enqueued) }
    end
  end
end
