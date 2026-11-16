require 'rails_helper'

RSpec.describe(Noticed::Notification) do
  describe '.policy_name' do
    it { expect(described_class.policy_name).to(eq('NotificationPolicy')) }
    it { expect(ShipmentNotifier::Notification.policy_name).to(eq('NotificationPolicy')) }
  end
end
