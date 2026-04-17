require 'rails_helper'

RSpec.describe(PickupNotifier) do
  let(:dispatcher) { build_stubbed(:user, first_name: 'Jane', last_name: 'Smith') }
  let(:notifier) { described_class.new }
  let(:shipment) { build_stubbed(:shipment) }

  let(:pickup) { instance_double(Pickup, shipment:, dispatcher:) }

  before { allow(notifier).to receive(:params).and_return({ pickup:, pickup_action_type: :pickup_service_dispatched }) }

  describe '#mailer_class' do
    it { expect(notifier.mailer_class).to eq(UserMailer) }
  end

  describe '#mailer_method' do
    it { expect(notifier.mailer_method).to eq(:pickup_service_dispatched) }
  end

  describe '#mailer_params' do
    it { expect(notifier.mailer_params).to eq({ pickup: }) }
  end

  describe '#notification_type' do
    it { expect(notifier.notification_type).to eq('pickup:pickup_service_dispatched') }
  end

  describe '#mapped_shipment' do
    it { expect(notifier.mapped_shipment).to eq(shipment) }
  end

  describe '#url' do
    it { expect(notifier.url).to eq("/broker/shipments/#{shipment.load_id}/transit?attr=dispatched_at") }
  end

  describe '#message' do
    it { expect(notifier.message).to eq("Jane Smith Dispatched Load #{shipment.load_id}") }
  end

  describe '#notification_subject' do
    it { expect(notifier.notification_subject).to eq(notifier.message) }
  end
end
