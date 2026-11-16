require 'rails_helper'

RSpec.describe(DocumentNotifier) do
  let(:from_user) { build_stubbed(:user) }
  let(:notifier) { described_class.new }
  let(:shipment) { build_stubbed(:shipment) }
  let(:to_contact) { build_stubbed(:contact) }

  before { allow(notifier).to receive(:params).and_return({ document_type: :carrier_bol, from_user:, shipment:, to_contact: }) }

  describe '#mailer_class' do
    it { expect(notifier.mailer_class).to eq(ContactMailer) }
  end

  describe '#mailer_method' do
    it { expect(notifier.mailer_method).to eq(:from_notification) }
  end

  describe '#mailer_params' do
    it { expect(notifier.mailer_params).to eq({ document_type: :carrier_bol, from_user:, shipment:, to_contact: }) }
  end

  describe '#notification_type' do
    it { expect(notifier.notification_type).to eq('document:carrier_bol') }
  end

  describe '#url' do
    it { expect(notifier.url).to eq("/broker/shipments/#{shipment.load_id}/documents?attr=carrier_bol") }
  end

  describe '#message' do
    it { expect(notifier.message).to eq("Scanned Bill of Landing for Load ##{shipment.load_id} is available") }
  end

  describe '#notification_subject' do
    it do
      expect(notifier.notification_subject)
        .to(eq("Your Scanned Bill of Landing is attached for the following shipment (Load ##{shipment.load_id})"))
    end
  end

  describe '#humanized_document_type' do
    {
      carrier_bol: 'Scanned Bill of Landing',
      carrier_pod: 'Proof of Delivery',
      broker_quote: 'Quote',
      broker_dispatch_sheet: 'Dispatch Sheet',
      broker_bol: 'Bill of Landing'
    }.each do |document_type, expected|
      context "when document_type is :#{document_type}" do
        before { allow(notifier).to receive(:params).and_return({ document_type:, shipment:, to_contact: }) }

        it { expect(notifier.humanized_document_type).to eq(expected) }
      end
    end
  end
end
