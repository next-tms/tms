require 'rails_helper'

RSpec.describe('Users::Invitations') do
  let(:carrier) { create(:carrier) }
  let(:contact) { create(:contact, companyable: carrier, email: 'billing@acme.test', first_name: 'Billie', last_name: 'Ng') }
  let(:current_user) { create(:broker_user).tap { |user| user.add_role(:accounts_payable) } }
  let(:hidden_fields) { Nokogiri::HTML(response.body).css('input[type=hidden]').to_h { |input| [input['name'], input['value']] } }
  let(:legacy_invitee) do
    create(:carrier_user, email: 'legacy@acme.test').tap do |user|
      user.devise_invitations.first.update!(
        invitation_accepted_at: nil,
        invitation_sent_at: 1.day.ago,
        invitation_token: Devise.token_generator.digest(User, :invitation_token, 'legacy-token'),
        invite_key: { email: 'legacy@acme.test' }
      )
    end
  end

  before do
    seed_settings
    create(:setting, key: 'robot_email', value: 'robot@example.com')
    sign_in(current_user)
  end

  describe 'GET /users/invitation/accept' do
    let(:invitation_token) { invitee.raw_invitation_token }
    let!(:invitee) { User.invite!({ email: 'new@acme.test', first_name: 'Billie', last_name: 'Ng' }, &:build_contact) }

    before do
      sign_out(current_user)
      get('/users/invitation/accept', params: { invitation_token: })
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(include('user[password_confirmation]')) }

    context 'with a token issued before the upgrade' do
      let(:invitation_token) { 'legacy-token' }
      let(:invitee) { legacy_invitee }

      it { is_expected.to(have_http_status(:ok)) }
    end

    context 'with an invalid token' do
      let(:invitation_token) { 'nope' }

      it { is_expected.to(redirect_to(root_path)) }
    end
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

    context 'with a valid carrier contact' do
      let(:user_params) do
        {
          companyable_id: carrier.id,
          companyable_type: 'Carrier',
          contact_id: contact.id,
          email: contact.email,
          first_name: 'Billie'
        }
      end

      it { is_expected.to(redirect_to(broker_carrier_users_path(carrier))) }
      it { expect(User.find_by(email: contact.email)).to(be_invitation_pending) }
      it { expect(ActionMailer::Base.deliveries.last.to).to(eq([contact.email])) }
    end

    context "when re-inviting another customer's pending user" do
      let(:current_user) do
        create(:broker_user).tap { |user| BrokerCustomerSalesRep.create!(broker_customer: own_customer, commission_percent: 5, user:) }
      end
      let(:own_customer) { create(:broker_customer) }
      let(:pending_user) { create(:customer_user, :invited) }
      let(:user_params) { { companyable_id: own_customer.id, companyable_type: 'BrokerCustomer', email: pending_user.email } }

      it { is_expected.to(have_http_status(:not_found)) }
      it { expect(pending_user.reload.companyable).not_to(eq(own_customer)) }

      context 'when the pending user is already at the same customer' do
        let(:pending_user) { create(:customer_user, :invited, companyable: own_customer) }

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

  describe 'PUT /users/invitation' do
    let(:invitation_token) { invitee.raw_invitation_token }
    let!(:invitee) { User.invite!({ email: 'new@acme.test', first_name: 'Billie', last_name: 'Ng' }, &:build_contact) }
    let(:password) { 'Correct horse battery staple 42' }
    let(:password_confirmation) { password }
    let(:referer) { "http://www.example.com/users/invitation/accept?invitation_token=#{CGI.escape(invitation_token)}" }

    before do
      sign_out(current_user)
      put('/users/invitation', headers: { 'Referer' => referer }, params: { user: { password:, password_confirmation: } })
    end

    it { is_expected.to(have_http_status(:redirect)) }
    it { expect(invitee.reload).to(be_invitation_accepted) }

    context 'with a token issued before the upgrade' do
      let(:invitation_token) { 'legacy-token' }
      let(:invitee) { legacy_invitee }

      it { is_expected.to(have_http_status(:redirect)) }
      it { expect(invitee.reload).to(be_invitation_accepted) }
    end

    context 'when the email changed after the first invitation' do
      let(:invitee) do
        original_token
        original_invitee.tap { |user| user.update!(email: 'renamed@acme.test') }
      end
      let(:original_invitee) { User.invite!({ email: 'new@acme.test', first_name: 'Billie', last_name: 'Ng' }, &:build_contact) }
      let(:original_token) { original_invitee.raw_invitation_token }

      it { expect(invitee.reload).to(be_invitation_accepted) }

      context 'with the original link' do
        let(:invitation_token) { original_token }

        it { expect(invitee.reload).not_to(be_invitation_accepted) }
        it { expect(invitee.reload.email).to(eq('renamed@acme.test')) }
      end
    end

    context 'when the password confirmation does not match' do
      let(:password_confirmation) { 'something else entirely' }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(invitee.reload).not_to(be_invitation_accepted) }
    end
  end
end
