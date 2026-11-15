require 'rails_helper'

RSpec.describe('Application layout') do
  let(:current_user) { create(:root_broker_user) }

  before do
    seed_settings
    sign_in(current_user)
    get(broker_shipments_path)
  end

  it { is_expected.to(have_http_status(:ok)) }
  it { expect(response.body).to(include('<meta name="turbo-prefetch" content="false"/>')) }
end
