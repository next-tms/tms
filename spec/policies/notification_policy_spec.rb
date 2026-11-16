require 'rails_helper'

RSpec.describe(NotificationPolicy) do
  let(:authorizable) { create(:broker_user) }
  let(:notification) { ShipmentNotifier.with(notifier_params).deliver(authorizable, enqueue_job: false).notifications.first }
  let(:notifier_params) { { attribute_changed: :new_shipment, shipment: } }
  let(:other_notification) { ShipmentNotifier.with(notifier_params).deliver(create(:broker_user), enqueue_job: false).notifications.first }
  let(:policy) { described_class.new(notification, authorizable:) }
  let(:shipment) { create(:shipment) }

  describe '#apply_scope' do
    subject { policy.apply_scope(Noticed::Notification.all, type: :active_record_relation) }

    before do
      notification
      other_notification
    end

    it { is_expected.to(contain_exactly(notification)) }
  end

  describe '#manage?' do
    subject { policy.apply(:manage?) }

    it { is_expected.to(be(true)) }

    context 'when the notification belongs to another user' do
      let(:policy) { described_class.new(other_notification, authorizable:) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#view?' do
    subject { policy.apply(policy.resolve_rule(:view?)) }

    it { is_expected.to(be(true)) }

    context 'when the notification belongs to another user' do
      let(:policy) { described_class.new(other_notification, authorizable:) }

      it { is_expected.to(be(false)) }
    end
  end
end
