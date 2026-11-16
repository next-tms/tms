require 'rails_helper'

RSpec.describe(BaseNotifier) do
  let(:notifier) { ShipmentNotifier.new }
  let(:shipment) { build_stubbed(:shipment) }

  before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: :new_shipment }) }

  describe '.delivery_methods' do
    subject { described_class.delivery_methods[:email].config }

    it { is_expected.to(include(if: :should_receive_email_notification?)) }
    it { is_expected.to(include(mailer: :mailer_class)) }
    it { is_expected.to(include(method: :mailer_method)) }
    it { is_expected.to(include(params: :mailer_params)) }
    it { is_expected.to(include(wait: 2.minutes)) }
  end

  describe '#failed_email_delivery?' do
    context 'when email_delivery_error param is present' do
      before { allow(notifier).to receive(:params).and_return({ email_delivery_error: 'SMTP timeout' }) }

      it { expect(notifier.failed_email_delivery?).to be(true) }
    end

    context 'when not email_delivery_error' do
      it { expect(notifier.failed_email_delivery?).to be(false) }
    end
  end

  describe '#should_receive_email_notification?' do
    let(:recipient) { build_stubbed(:user, receive_email_notifications: true) }

    let(:notification) { instance_double(Noticed::Notification, recipient:, unread?: true) }

    context 'when not receive_email_notifications' do
      let(:recipient) { build_stubbed(:user, receive_email_notifications: false) }

      it { expect(notifier.should_receive_email_notification?(notification)).to be(false) }
    end

    context 'when notification is read and not receive_read_notifications_by_email' do
      let(:notification) { instance_double(Noticed::Notification, recipient:, unread?: false) }

      it { expect(notifier.should_receive_email_notification?(notification)).to be(false) }
    end

    context 'when notification_type is blacklisted' do
      let(:recipient) { build_stubbed(:user, receive_email_notifications: true, email_notifications_blacklist: 'shipment:new_shipment') }

      it { expect(notifier.should_receive_email_notification?(notification)).to be(false) }
    end

    context 'when notification is read and receive_read_notifications_by_email' do
      let(:recipient) { build_stubbed(:user, receive_email_notifications: true, receive_read_notifications_by_email: true) }
      let(:notification) { instance_double(Noticed::Notification, recipient:, unread?: false) }

      it { expect(notifier.should_receive_email_notification?(notification)).to be(true) }
    end

    context 'when all conditions are met' do
      it { expect(notifier.should_receive_email_notification?(notification)).to be(true) }
    end
  end
end
