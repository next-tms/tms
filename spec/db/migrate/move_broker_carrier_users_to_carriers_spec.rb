require 'rails_helper'
require Rails.root.join('db/migrate/20261103213308_move_broker_carrier_users_to_carriers')

RSpec.describe(MoveBrokerCarrierUsersToCarriers) do
  let(:broker_carrier) { create(:broker_carrier) }
  let(:customer_user) { create(:customer_user) }
  let(:migration) { described_class.new }
  let(:user) { create(:broker_user) }
  let(:user_model) { described_class::User }

  before do
    user_model.where(id: user.id).update_all(companyable_id: broker_carrier.id, companyable_type: 'BrokerCarrier') # rubocop:disable Rails/SkipsModelValidations
    customer_user

    ActiveRecord::Migration.suppress_messages { migration.up }
  end

  describe '#down' do
    it { expect { migration.down }.to(raise_error(ActiveRecord::IrreversibleMigration)) }
  end

  describe '#up' do
    it { expect(user_model.find(user.id)).to(have_attributes(companyable_id: broker_carrier.carrier_id, companyable_type: 'Carrier')) }
    it { expect(user_model.find(customer_user.id).companyable_type).to(eq('BrokerCustomer')) }
  end
end
