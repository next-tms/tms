require 'rails_helper'

RSpec.describe('Broker::Users') do
  subject { response }

  let(:current_user) { create(:root_broker_user) }

  before do
    seed_settings
    create(:setting, key: 'robot_email', value: 'robot@example.com')
    sign_in(current_user)
  end

  describe 'GET /broker/users' do
    let!(:invited_user) { create(:broker_user, :invited) }

    before { get('/broker/users', params: { q: { s: 'invitation_accepted_at asc' } }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:users)).to(all(satisfy { |user| user.association(:accepted_invitation).loaded? })) }
    it { expect(assigns(:users).last).to(eq(invited_user)) }
  end
end
