# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Users::InvitationsController) do
  let(:current_user) { create(:root_broker_user) }
  let(:broker) { current_user.companyable }

  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
    sign_in(current_user)
  end

  describe 'POST #create' do
    subject(:invite) { post(:create, params:) }

    context 'when inviting a broker user' do
      let(:params) do
        {
          user: {
            companyable_id: broker.id,
            companyable_type: 'Broker',
            email: Faker::Internet.unique.email,
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name
          }
        }
      end

      before { invite }

      it { expect(response).to(redirect_to(broker_users_path)) }
      it { expect(User.last.email).to(eq(params.dig(:user, :email))) }
      it { expect(ActionMailer::Base.deliveries).not_to(be_empty) }
    end

    context 'when inviting a customer user' do
      let(:broker_customer) { create(:broker_customer, broker:) }
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

      it { expect(response).to(redirect_to(broker_users_path)) }
      it { expect(User.last.email).to(eq(params.dig(:user, :email))) }
      it { expect(ActionMailer::Base.deliveries).not_to(be_empty) }
    end

    context 'when the user already exists (re-invitation)' do
      let(:existing_user) { create(:broker_user, companyable: broker, invitation_accepted_at: nil) }
      let(:params) do
        {
          user: {
            companyable_id: broker.id,
            companyable_type: 'Broker',
            email: existing_user.email,
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name
          }
        }
      end

      before { invite }

      it { expect(response).to(redirect_to(broker_users_path)) }
    end
  end
end
