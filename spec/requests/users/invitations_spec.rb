require 'rails_helper'

RSpec.describe('Users::Invitations') do
  let(:carrier) { create(:carrier) }
  let(:contact) { create(:contact, companyable: carrier, email: 'billing@acme.test', first_name: 'Billie', last_name: 'Ng') }
  let(:current_user) { create(:broker_user).tap { |user| user.add_role(:accounts_payable) } }
  let(:hidden_fields) { Nokogiri::HTML(response.body).css('input[type=hidden]').to_h { |input| [input['name'], input['value']] } }

  before do
    seed_settings
    create(:setting, key: 'robot_email', value: 'robot@example.com')
    sign_in(current_user)
  end

  describe 'GET /users/invitation/new' do
    before { get('/users/invitation/new', params: { companyable_id: carrier.id, companyable_type: 'Carrier', contact_id: contact.id }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(include('Inviting carrier')) }
    it { expect(hidden_fields).to(include('user[companyable_type]' => 'Carrier', 'user[contact_id]' => contact.id.to_s)) }
    it { expect(hidden_fields).to(include('user[email]' => contact.email)) }

    context 'when not in accounts payable' do
      let(:current_user) { create(:broker_user) }

      it { expect(response.body).to(include('Access denied')) }
    end
  end

  describe 'POST /users/invitation' do
    let(:user_params) { { companyable_id: carrier.id, companyable_type: 'Carrier', email: 'not an email', first_name: 'Billie' } }

    before { post('/users/invitation', params: { user: user_params }) }

    it { expect(response.body).to(include('Inviting carrier')) }
    it { expect(response.body).not_to(include('Access denied')) }
    it { expect(hidden_fields).to(include('user[companyable_id]' => carrier.id.to_s, 'user[companyable_type]' => 'Carrier')) }

    context "when re-inviting another customer's pending user" do
      let(:current_user) do
        create(:broker_user).tap { |user| BrokerCustomerSalesRep.create!(broker_customer: own_customer, commission_percent: 5, user:) }
      end
      let(:own_customer) { create(:broker_customer) }
      let(:pending_user) { create(:customer_user, invitation_accepted_at: nil) }
      let(:user_params) { { companyable_id: own_customer.id, companyable_type: 'BrokerCustomer', email: pending_user.email } }

      it { is_expected.to(have_http_status(:not_found)) }
      it { expect(pending_user.reload.companyable).not_to(eq(own_customer)) }

      context 'when the pending user is already at the same customer' do
        let(:pending_user) { create(:customer_user, companyable: own_customer, invitation_accepted_at: nil) }

        it { is_expected.not_to(have_http_status(:not_found)) }
      end
    end

    context "with another company's contact" do
      let(:other_contact) { create(:contact, companyable: create(:broker_customer), email: 'other@acme.test') }
      let(:user_params) { { companyable_id: carrier.id, companyable_type: 'Carrier', contact_id: other_contact.id, email: 'x@acme.test' } }

      it { is_expected.to(have_http_status(:not_found)) }
      it { expect(other_contact.reload.companyable_type).to(eq('BrokerCustomer')) }
    end

    context 'when the inviter cannot invite carrier users' do
      let(:current_user) { create(:customer_user).tap { |user| user.add_role(:root) } }
      let(:user_params) { { companyable_id: carrier.id, companyable_type: 'Carrier', email: 'new@acme.test', first_name: 'Billie' } }

      it { is_expected.to(have_http_status(:not_found)) }
      it { expect(User.find_by(email: 'new@acme.test')).to(be_nil) }
    end
  end
end
