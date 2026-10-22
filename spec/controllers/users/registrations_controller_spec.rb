require 'rails_helper'

RSpec.describe(Users::RegistrationsController) do
  let(:current_user) { create(:root_broker_user) }

  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
    create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles')
    sign_in(current_user)
  end

  describe 'PUT #update' do
    before { put(:update, params: { user: { current_password: current_user.password, time_zone_name: 'America/Denver' } }) }

    it { expect(current_user.reload.time_zone_name).to(eq('America/Denver')) }

    context 'when time_zone_name does not resolve' do
      before { put(:update, params: { user: { current_password: current_user.password, time_zone_name: 'not-a-zone' } }) }

      it { expect(current_user.reload.time_zone_name).to(eq('America/Denver')) }
    end
  end
end
