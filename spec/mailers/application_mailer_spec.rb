require 'rails_helper'

RSpec.describe(ApplicationMailer) do
  describe '#notify_sentry_and_store_error_msg' do
    let(:error) { StandardError.new('Inactive recipient') }
    let(:event) { ShipmentNotifier.with(attribute_changed: :new_shipment, shipment:).deliver(recipient, enqueue_job: false) }
    let(:mailer) { described_class.new }
    let(:recipient) { create(:broker_user) }
    let(:shipment) { create(:shipment) }

    before do
      allow(Sentry).to(receive(:capture_exception))
      mailer.params = mailer_params
      mailer.notify_sentry_and_store_error_msg(error)
    end

    context 'with a notification' do
      let(:mailer_params) { { notification: event.notifications.first } }

      it { expect(Sentry).to(have_received(:capture_exception).with(error)) }
      it { expect(event.reload.params[:email_delivery_error]).to(eq('StandardError | Inactive recipient')) }
    end

    context 'without a notification' do
      let(:mailer_params) { {} }

      it { expect(Sentry).to(have_received(:capture_exception).with(error)) }
    end
  end
end
