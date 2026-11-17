require 'rails_helper'

RSpec.describe(Tools::ArgumentSchema) do
  describe '.call' do
    subject(:schema) { described_class.call(Types::AddressInputObject.arguments.values) }

    it { is_expected.to(include(required: %i[city region_iso31662 zip_code], type: 'object')) }
    it { expect(schema[:properties].keys).to(eq(%i[city region_iso31662 street street2 zip_code])) }
  end

  describe '.property' do
    subject { described_class.property(Types::PackageInputObject.arguments.fetch(name)) }

    let(:name) { 'height' }

    it { is_expected.to(eq(description: 'Inches', type: 'integer')) }

    context 'without a description' do
      let(:name) { 'quantity' }

      it { is_expected.to(eq(type: 'integer')) }
    end
  end

  describe '.property_name' do
    subject { described_class.property_name(Mutations::QuoteCreate.input_type.arguments.fetch('customerId')) }

    it { is_expected.to(eq(:customer_id)) }
  end

  describe '.type' do
    subject { described_class.type(graphql_type) }

    let(:graphql_type) { GraphQL::Types::String }

    it { is_expected.to(eq(type: 'string')) }

    context 'with a Boolean' do
      let(:graphql_type) { GraphQL::Types::Boolean }

      it { is_expected.to(eq(type: 'boolean')) }
    end

    context 'with a date' do
      let(:graphql_type) { GraphQL::Types::ISO8601Date }

      it { is_expected.to(eq(format: 'date', type: 'string')) }
    end

    context 'with a date and time' do
      let(:graphql_type) { GraphQL::Types::ISO8601DateTime }

      it { is_expected.to(eq(format: 'date-time', type: 'string')) }
    end

    context 'with a Float' do
      let(:graphql_type) { GraphQL::Types::Float }

      it { is_expected.to(eq(type: 'number')) }
    end

    context 'with an enum' do
      let(:graphql_type) { Types::PackagingEnum }

      it { is_expected.to(include(enum: include('crate', 'pallet'), type: 'string')) }
    end

    context 'with an enum without static values' do
      let(:graphql_type) { Types::Iso31662Type }

      it { is_expected.to(eq(description: Types::Iso31662Type.description, type: 'string')) }
    end

    context 'with an input object' do
      let(:graphql_type) { Types::AddressInputObject }

      it { is_expected.to(include(required: %i[city region_iso31662 zip_code], type: 'object')) }
    end

    context 'with an Int' do
      let(:graphql_type) { GraphQL::Types::Int }

      it { is_expected.to(eq(type: 'integer')) }
    end

    context 'with a non-null list' do
      let(:graphql_type) { GraphQL::Types::Int.to_non_null_type.to_list_type.to_non_null_type }

      it { is_expected.to(eq(items: { type: 'integer' }, type: 'array')) }
    end
  end
end
