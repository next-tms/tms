require 'rails_helper'

RSpec.describe(ContactMailer) do
  describe '#from_notification' do
    subject(:mail) { ActionMailer::Base.deliveries.last }

    let(:event) { notifier.deliver(recipient, enqueue_job: false) }
    let(:notifier) { DocumentNotifier.with(document_type: :carrier_bol, from_user: nil, shipment:, to_contact:) }
    let(:recipient) { create(:broker_user, receive_email_notifications: true) }
    let(:shipment) { create(:shipment) }
    let(:to_contact) { create(:contact) }

    before do
      create(:setting, key: 'name', value: 'Acme Freight')
      create(:setting, key: 'robot_email', value: 'robot@acme.test')
      shipment.carrier_bol.attach(ActiveStorage::Blob.create_and_upload!(io: file_fixture('pod.pdf').open, filename: 'bol.pdf'))
      Noticed::DeliveryMethods::Email.new.perform(:email, event.notifications.first)
    end

    it { expect(mail.attachments.map(&:filename)).to(eq(['bol.pdf'])) }
    it { expect(mail.subject).to(eq("Scanned Bill of Landing for Load #{shipment.load_id}")) }
    it { expect(mail.to).to(eq([to_contact.email])) }
  end
end
