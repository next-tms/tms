require 'rails_helper'

RSpec.describe(Ransackable) do
  let(:broker) { build(:broker_user) }
  let(:carrier) { build(:carrier_user) }
  let(:customer) { build(:customer_user) }

  describe '.broker_authorizable?' do
    it { expect(Shipment.broker_authorizable?(broker)).to(be(true)) }
    it { expect(Shipment.broker_authorizable?(carrier)).to(be(false)) }
    it { expect(Shipment.broker_authorizable?(customer)).to(be(false)) }
    it { expect(Shipment.broker_authorizable?(nil)).to(be(false)) }
    it { expect(Shipment.broker_authorizable?(build(:customer))).to(be(false)) }
  end

  describe '.broker_only_column?' do
    it { expect(BrokerCustomer.broker_only_column?('internal_notes')).to(be(true)) }
    it { expect(BrokerCarrier.broker_only_column?('accounting_notes')).to(be(true)) }
    it { expect(Shipment.broker_only_column?('broker_notes')).to(be(true)) }
    it { expect(Shipment.broker_only_column?('public_notes')).to(be(false)) }
    it { expect(BrokerCustomer.ransackable_attributes).not_to(include('internal_notes')) }
    it { expect(BrokerCustomer.ransackable_attributes(broker)).to(include('internal_notes')) }
  end

  describe '.json_column?' do
    it { expect(Rate.json_column?('breakdown')).to(be(true)) }
    it { expect(Rate.json_column?('reference')).to(be(false)) }
  end

  describe '.pricing_column?' do
    it { expect(Shipment.pricing_column?('total_cost_cents')).to(be(true)) }
    it { expect(Shipment.pricing_column?('carrier_charge_currency')).to(be(true)) }
    it { expect(BrokerCustomer.pricing_column?('default_upcharge_percentage')).to(be(true)) }
    it { expect(BrokerCustomerSalesRep.pricing_column?('commission_percent')).to(be(true)) }
    it { expect(Shipment.pricing_column?('shipper_name')).to(be(false)) }
  end

  describe '.private_associations' do
    it { expect(Shipment.private_associations(broker)).to(be_empty) }
    it { expect(Shipment.private_associations(carrier)).to(eq(['broker_customer'])) }
    it { expect(Shipment.private_associations(customer)).to(eq(['broker_carrier'])) }
    it { expect(Shipment.private_associations(nil)).to(be_empty) }
  end

  describe '.ransackable_associations' do
    it do
      associations = Accessorial.reflect_on_all_associations.reject(&:collection?).map { |reflection| reflection.name.to_s }

      expect(Accessorial.ransackable_associations(broker)).to(eq(associations))
    end

    it { expect(Customer.ransackable_associations(broker)).not_to(include('broker_customers')) }
    it { expect(Accessorial.ransackable_associations(customer)).to(be_empty) }
    it { expect(Accessorial.ransackable_associations).to(be_empty) }
  end

  describe '.ransackable_attributes' do
    it { expect(Shipment.ransackable_attributes).to(include('broker_carrier_id', 'load_id', 'pro', 'shipper_name', 'status')) }
    it { expect(Shipment.ransackable_attributes).not_to(include('carrier_charge_cents', 'total_charges_cents', 'total_cost_cents')) }
    it { expect(Shipment.ransackable_attributes(broker)).to(include('carrier_charge_cents', 'total_charges_cents', 'total_cost_cents')) }
    it { expect(Shipment.ransackable_attributes(carrier)).not_to(include('total_charges_cents', 'total_cost_cents')) }
    it { expect(Shipment.ransackable_attributes(customer)).not_to(include('total_charges_cents', 'total_cost_cents')) }
    it { expect(Shipment.ransackable_attributes).to(eq(Shipment.ransackable_attributes.sort)) }
    it { expect(Payment.ransackable_attributes).to(include('id')) }
    it { expect(Rate.ransackable_attributes(broker)).not_to(include('breakdown')) }
    it { expect(User.ransackable_attributes(broker)).to(include('email', 'first_name', 'last_name')) }
  end

  describe '.secret_column?' do
    it { expect(User.secret_column?('encrypted_password')).to(be(true)) }
    it { expect(User.secret_column?('invitation_token')).to(be(true)) }
    it { expect(User.secret_column?('last_sign_in_ip')).to(be(true)) }
    it { expect(User.secret_column?('reset_password_token')).to(be(true)) }
    it { expect(APIKey.secret_column?('token_digest')).to(be(true)) }
    it { expect(BrokerCarrier.secret_column?('username')).to(be(true)) }
    it { expect(Integration.secret_column?('credentials')).to(be(true)) }
    it { expect(User.secret_column?('email')).to(be(false)) }
  end
end
