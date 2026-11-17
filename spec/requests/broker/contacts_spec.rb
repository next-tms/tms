require 'rails_helper'

RSpec.describe('Broker::Contacts') do
  subject { response }

  let(:current_user) { create(:root_broker_user) }

  before do
    seed_settings
    create(:setting, key: 'robot_email', value: 'robot@example.com')
    sign_in(current_user)
  end

  describe 'GET /broker/contacts/:id' do
    before { get("/broker/contacts/#{user.contact_id}") }

    context 'when the user accepted the invitation' do
      let(:user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body).to(include('alert-success')) }
    end

    context 'when the user has not accepted the invitation' do
      let(:user) { create(:broker_user, :invited) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body).to(include('alert-warning')) }
    end
  end
end
