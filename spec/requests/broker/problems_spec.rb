require 'rails_helper'

RSpec.describe('Broker::Problems') do
  subject { response }

  let(:current_user) { create(:root_broker_user) }
  let(:problem) { create(:problem, problematic_rule_code: 'missing_pro', resolvable: shipment) }
  let(:shipment) { create(:shipment) }

  before do
    seed_settings
    create(:setting, key: 'mailing_address', value: create(:address))
    sign_in(current_user)
  end

  describe 'GET /broker/tasks/:id' do
    before { get("/broker/tasks/#{problem.id}") }

    it { is_expected.to(have_http_status(:ok)) }
  end
end
