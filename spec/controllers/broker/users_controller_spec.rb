require 'rails_helper'

# @todo Test all user types
RSpec.describe(Broker::UsersController) do
  let(:current_user) { create(:root_broker_user) }
  let(:user) { create(:broker_user, companyable: current_user.companyable) }

  before { sign_in(current_user) }

  describe '#user_params' do
    subject { controller.__send__(:user_params).to_h }

    let(:attributes) { { contact_attributes: { contact_roles_attributes: { '0' => { role: 'dispatch' } }, id: '1' }, first_name: 'Ada' } }

    before { controller.params = { user: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end

  describe 'GET #show' do
    before { get(:show, params: { id: user.id }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:user)).to(eq(user)) }
  end

  describe 'PATCH #update' do
    let(:params) do
      {
        id: user.id,
        user: {
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name
        }
      }
    end

    before { patch(:update, params:) }

    it { is_expected.to(redirect_to(broker_user_path(user))) }
    it { expect(assigns(:user)).to(eq(user)) }
    it { expect(flash[:success]).to(eq('Successfully Updated User')) }
  end
end
