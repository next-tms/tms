require 'rails_helper'

RSpec.describe(ContactMailer) do
  let(:bol) { ActiveStorage::Blob.create_and_upload!(content_type: 'application/pdf', filename: 'bol.pdf', io: StringIO.new('bol')) }
  let(:ebol) { ActiveStorage::Blob.create_and_upload!(content_type: 'application/vnd.nmfta.ebol+json', filename: 'bol.ebol.json', io: StringIO.new('{}')) }
  let(:from_user) { create(:root_broker_user) }
  let(:quote) { ActiveStorage::Blob.create_and_upload!(content_type: 'application/pdf', filename: 'quote.pdf', io: StringIO.new('quote')) }
  let(:shipment) do
    create(:shipment, :usd).tap do |shipment|
      shipment.broker_bol.attach(bol)
      shipment.broker_ebol.attach(ebol) if ebol
      shipment.broker_quote.attach(quote)
    end
  end
  let(:to_contact) { create(:contact) }

  before do
    allow(DocumentableService).to(receive(:call))
    create(:setting, key: 'name', value: 'Broker Co')
    create(:setting, key: 'robot_email', value: 'robot@broker.test')
  end

  describe '#broker_bol' do
    subject(:mail) { described_class.broker_bol(from_user:, shipment:, to_contact:) }

    it { expect(mail.attachments.map(&:filename)).to(contain_exactly('bol.pdf', 'bol.ebol.json')) }
    it { expect(mail.attachments['bol.ebol.json'].mime_type).to(eq('application/vnd.nmfta.ebol+json')) }

    context 'without an eBOL' do
      let(:ebol) { nil }

      it { expect(mail.attachments.map(&:filename)).to(contain_exactly('bol.pdf')) }
    end
  end

  describe '#broker_ebol' do
    subject(:mail) { described_class.broker_ebol(from_user:, shipment:, to_contact:) }

    it { expect(mail.attachments.map(&:filename)).to(contain_exactly('bol.ebol.json')) }
    it { expect(mail.subject).to(eq("eBOL for Load #{shipment.load_id}")) }
  end

  describe '#broker_quote' do
    subject(:mail) { described_class.broker_quote(from_user:, shipment:, to_contact:) }

    it { expect(mail.attachments.map(&:filename)).to(contain_exactly('quote.pdf')) }
  end

  describe '#from_notification' do
    subject(:mail) { ActionMailer::Base.deliveries.last }

    let(:event) { notifier.deliver(recipient, enqueue_job: false) }
    let(:notifier) { DocumentNotifier.with(document_type: :carrier_bol, from_user: nil, shipment:, to_contact:) }
    let(:recipient) { create(:broker_user, receive_email_notifications: true) }

    before do
      shipment.carrier_bol.attach(ActiveStorage::Blob.create_and_upload!(io: file_fixture('pod.pdf').open, filename: 'scanned_bol.pdf'))
      Noticed::DeliveryMethods::Email.new.perform(:email, event.notifications.first)
    end

    it { expect(mail.attachments.map(&:filename)).to(eq(['scanned_bol.pdf'])) }
    it { expect(mail.subject).to(eq("Scanned Bill of Landing for Load #{shipment.load_id}")) }
    it { expect(mail.to).to(eq([to_contact.email])) }

    context 'with a BOL' do
      let(:notifier) { DocumentNotifier.with(document_type: :broker_bol, from_user: nil, shipment:, to_contact:) }

      it { expect(mail.attachments.map(&:filename)).to(contain_exactly('bol.pdf', 'bol.ebol.json')) }
    end
  end
end
