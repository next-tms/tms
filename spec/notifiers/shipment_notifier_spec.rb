require 'rails_helper'

RSpec.describe(ShipmentNotifier) do
  let(:notifier) { described_class.new }
  let(:shipment) { build_stubbed(:shipment) }

  before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: :new_shipment }) }

  describe '#mailer_class' do
    it { expect(notifier.mailer_class).to eq(UserMailer) }
  end

  describe '#mailer_method' do
    it { expect(notifier.mailer_method).to eq(:new_shipment) }
  end

  describe '#mailer_params' do
    it { expect(notifier.mailer_params).to eq({ actor: nil, shipment: }) }

    context 'when actor is present' do
      let(:actor) { build_stubbed(:broker_user) }

      before { allow(notifier).to receive(:params).and_return({ actor:, attribute_changed: :new_shipment, shipment: }) }

      it { expect(notifier.mailer_params).to eq({ actor:, shipment: }) }
    end
  end

  describe '#notification_type' do
    it { expect(notifier.notification_type).to eq('shipment:new_shipment') }
  end

  describe '#url' do
    context 'when attribute_changed is :new_shipment' do
      it { expect(notifier.url).to eq("/broker/shipments/#{shipment.load_id}") }
    end

    context 'when attribute_changed is :canceled_at' do
      before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: :canceled_at }) }

      it { expect(notifier.url).to eq("/broker/shipments/#{shipment.load_id}") }
    end

    context 'when attribute_changed is :dispatcher_id' do
      before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: :dispatcher_id }) }

      it { expect(notifier.url).to eq("/broker/shipments/#{shipment.load_id}?attr=dispatcher_id") }
    end

    context 'when attribute_changed is :delivered_at' do
      before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: :delivered_at }) }

      it { expect(notifier.url).to eq("/broker/shipments/#{shipment.load_id}/transit?attr=delivered_at") }
    end
  end

  describe '#message' do
    let(:shipment) { create(:shipment) }

    context 'when attribute_changed is :new_shipment' do
      it { expect(notifier.message).to eq("Robot Entered Load ##{shipment.load_id}") }
    end

    context 'when attribute_changed is :canceled_at' do
      before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: :canceled_at }) }

      it { expect(notifier.message).to eq("Robot Cancelled Load ##{shipment.load_id}") }
    end

    context 'when attribute_changed is :delivery_eta_on' do
      before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: :delivery_eta_on }) }

      it { expect(notifier.message).to eq("Robot Updated Load ##{shipment.load_id} ETA") }
    end

    context 'when attribute_changed is :dispatcher_id' do
      before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: :dispatcher_id }) }

      it { expect(notifier.message).to eq("Robot assigned ##{shipment.load_id} to you") }
    end

    context 'when attribute_changed is :delivered_at' do
      before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: :delivered_at }) }

      it { expect(notifier.message).to eq("Robot Marked Load ##{shipment.load_id} Delivered") }
    end

    context 'when attribute_changed is :picked_up_at' do
      before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: :picked_up_at }) }

      it { expect(notifier.message).to eq("Robot Marked Load ##{shipment.load_id} Picked Up") }
    end

    context 'when actor differs from shipment.updated_by' do
      let(:actor) { create(:broker_user) }
      let(:shipment) { create(:shipment, updated_by: create(:broker_user)) }

      before { allow(notifier).to receive(:params).and_return({ actor:, attribute_changed: :new_shipment, shipment: }) }

      it { expect(notifier.message).to eq("#{actor.full_name} Entered Load ##{shipment.load_id}") }
    end
  end

  describe '#notification_subject' do
    let(:shipment) { create(:shipment) }

    it { expect(notifier.notification_subject).to eq(notifier.message) }
  end

  describe '#humanized_attribute_changed' do
    {
      delivered_at: 'Delivered',
      delivery_appointment_at: 'Scheduled for Delivery',
      delivery_appointment_on: 'Scheduled for Delivery',
      out_for_delivery_at: 'Out for Delivery',
      picked_up_at: 'Picked Up'
    }.each do |attribute, expected|
      context "when attribute_changed is :#{attribute}" do
        before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: attribute }) }

        it { expect(notifier.humanized_attribute_changed).to eq(expected) }
      end
    end

    context 'when attribute_changed is :departed_origin_terminal_at' do
      before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: :departed_origin_terminal_at }) }

      it { expect(notifier.humanized_attribute_changed).to eq('Departed from Origin Terminal"') }
    end

    context 'when attribute_changed is :booked_at and not booked_at.blank?' do
      before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: :booked_at }) }

      it { expect(notifier.humanized_attribute_changed).to eq('Booked') }
    end

    context 'when attribute_changed is :booked_at and booked_at.blank?' do
      let(:shipment) { build_stubbed(:shipment, booked_at: nil) }

      before { allow(notifier).to receive(:params).and_return({ shipment:, attribute_changed: :booked_at }) }

      it { expect(notifier.humanized_attribute_changed).to eq('Unbooked') }
    end
  end
end
