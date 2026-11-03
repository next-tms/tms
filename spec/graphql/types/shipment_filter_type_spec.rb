require 'rails_helper'

RSpec.describe(Types::ShipmentFilterType) do
  subject(:arguments) { described_class.arguments }

  describe '.add_attribute_arguments' do
    it { expect(arguments['createdAtGteq'].type.graphql_name).to(eq('ISO8601DateTime')) }
    it { expect(arguments['shipperNameCont'].type.graphql_name).to(eq('String')) }
    it { expect(arguments['shipperNameIn'].type.to_type_signature).to(eq('[String!]')) }
    it { expect(arguments['statusNull'].type.graphql_name).to(eq('Boolean')) }
  end

  describe '.add_model_arguments' do
    it { expect(arguments).to(include('brokerCarrierCarrierScacEq', 'brokerCustomerCustomerNameCont', 'shipperAddressCityEq')) }
    it { expect(arguments).to(include('brokerCarrierIdEq', 'customerReferenceEq')) }
    it { expect(arguments).not_to(include('brokerCarrierQuotePaddingCentsGt', 'brokerCarrierUsernameEq')) }
    it { expect(arguments).not_to(include('totalChargesCentsGt', 'totalCostCentsGt')) }
    it { expect(arguments['brokerCarrierShipmentsCountGt'].type.graphql_name).to(eq('Int')) }
    it { expect(arguments['brokerCustomerIdEq'].type.graphql_name).to(eq('Int')) }
    it { expect(arguments['brokerCustomerCustomerIdIn'].type.to_type_signature).to(eq('[Int!]')) }
    it { expect(Types::BrokerCarrierFilterType.arguments['shipmentsCountNotIn'].type.to_type_signature).to(eq('[Int!]')) }
  end

  describe '.attribute_type' do
    it { expect(described_class.attribute_type(Shipment, 'load_id_text')).to(eq(:string)) }
    it { expect(described_class.attribute_type(Shipment, 'created_at')).to(eq(:datetime)) }
    it { expect(described_class.attribute_type(BrokerCarrier, 'shipments_count')).to(eq(:integer)) }
    it { expect(described_class.attribute_type(BrokerCarrier, 'name')).to(be_nil) }
  end

  describe '.filters' do
    let(:name_arguments) { described_class::PREDICATES[:string].keys.map { |suffix| "name_#{suffix}".camelize(:lower) } }

    it { expect(arguments['or'].type.to_type_signature).to(eq('[ShipmentFilter!]')) }
    it { expect(Types::CustomerFilterType.arguments.keys).to(include('or', *name_arguments)) }
  end

  describe '.ransackable_reflections' do
    let(:reflection_names) { described_class.ransackable_reflections(Shipment).map(&:name) }

    it { expect(reflection_names).to(contain_exactly(:broker_carrier, :broker_customer, :receiver_address, :shipper_address)) }
    it { expect(described_class.ransackable_reflections(Customer)).to(be_empty) }
  end
end
