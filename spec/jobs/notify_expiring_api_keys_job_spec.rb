require 'rails_helper'

RSpec.describe(NotifyExpiringAPIKeysJob) do
  subject(:perform) { described_class.perform_now }

  let!(:expiring_api_key) { create(:api_key, ttl: 7.days + 1.hour) }
  let!(:rolled_api_key) { create(:api_key, ttl: 7.days + 1.hour) }

  before do
    create(:api_key, ttl: 30.days)
    rolled_api_key.roll!(grace_period: 8.days)
  end

  it { expect { perform }.to(have_enqueued_mail(APIKeyMailer, :expiring).with(params: { api_key: expiring_api_key }, args: [])) }
  it { expect { perform }.to(have_enqueued_mail(APIKeyMailer, :expiring).with(params: { api_key: rolled_api_key.rolled_to }, args: [])) }
  it { expect { perform }.not_to(have_enqueued_mail(APIKeyMailer, :expiring).with(params: { api_key: rolled_api_key }, args: [])) }
end
