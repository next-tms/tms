require 'rails_helper'

RSpec.describe(Users::InvitationsController) do
  let(:current_user) { create(:root_broker_user) }

  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
    sign_in(current_user)
  end

  describe 'GET #new' do
    context 'when companyable params are blank' do
      before { get(:new) }

      it { expect(controller.__send__(:resource)).to(be_broker) }
    end

    context 'when companyable params are present' do
      let(:broker_customer) { create(:broker_customer) }

      before { get(:new, params: { companyable_id: broker_customer.id, companyable_type: 'BrokerCustomer' }) }

      it { expect(controller.__send__(:resource).companyable).to(eq(broker_customer)) }
    end
  end

  describe 'POST #create' do
    subject(:invite) { post(:create, params:) }

    before do
      create(:setting, key: 'robot_email', value: 'robot@example.com')
      create(:setting, key: 'time_zone_name', value: 'America/Chicago')
    end

    context 'when inviting a broker user' do
      let(:params) do
        {
          user: {
            companyable_id: '',
            companyable_type: '',
            email: Faker::Internet.unique.email,
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name
          }
        }
      end

      before { invite }

      it { is_expected.to(redirect_to(broker_users_path)) }
      it { expect(User.last.email).to(eq(params.dig(:user, :email))) }
      it { expect(User.last.time_zone_name).to(eq('America/Chicago')) }
      it { expect(User.last).to(be_broker) }
      it { expect(User.last.companyable_type).to(be_nil) }
      it { expect(ActionMailer::Base.deliveries).not_to(be_empty) }
    end

    context 'when inviting a carrier user from a contact' do
      let(:carrier) { create(:carrier) }
      let(:contact) { create(:contact, companyable: carrier, email: 'billing@acme.test', first_name: 'Billie', last_name: 'Ng') }
      let(:params) do
        {
          user: {
            companyable_id: carrier.id,
            companyable_type: 'Carrier',
            contact_id: contact.id,
            email: contact.email,
            first_name: contact.first_name,
            last_name: contact.last_name
          }
        }
      end

      before { invite }

      it { is_expected.to(redirect_to("/broker/carriers/#{carrier.id}/users")) }
      it { expect(User.last).to(have_attributes(carrier?: true, companyable: carrier, contact:)) }
      it { expect(User.last.time_zone_name).to(eq('America/Chicago')) }
    end

    context 'when inviting a customer user' do
      let(:broker_customer) { create(:broker_customer) }
      let(:params) do
        {
          user: {
            companyable_id: broker_customer.id,
            companyable_type: 'BrokerCustomer',
            email: Faker::Internet.unique.email,
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name
          }
        }
      end

      before { invite }

      it { is_expected.to(redirect_to(broker_users_path)) }
      it { expect(User.last.email).to(eq(params.dig(:user, :email))) }
      it { expect(User.last.time_zone_name).to(eq(broker_customer.office_address.time_zone_name)) }
      it { expect(ActionMailer::Base.deliveries).not_to(be_empty) }
    end

    context 'when the user already exists (re-invitation)' do
      let(:existing_user) { create(:broker_user, invitation_accepted_at: nil) }
      let(:params) do
        {
          user: {
            companyable_id: '',
            companyable_type: '',
            email: existing_user.email,
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name
          }
        }
      end

      before { invite }

      it { is_expected.to(redirect_to(broker_users_path)) }
    end
  end
end
