require 'rails_helper'

RSpec.describe(Types::BaseField) do
  describe '#description' do
    subject { field.description }

    let(:field) { Types::QueryType.get_field('shipment') }

    it { is_expected.to(eq(Types::Translation.call(:fields, :query, :shipment))) }

    context 'with a mutation field' do
      let(:field) { Types::MutationType.get_field('quoteCreate') }

      it { is_expected.to(eq(Types::Translation.call(:fields, :mutation, :quote_create))) }
    end

    context 'without a translation' do
      let(:field) { Types::ShipmentType.get_field('loadId') }

      it { is_expected.to(be_nil) }
    end

    context 'with an explicit description and no translation' do
      let(:field) { described_class.new(description: 'Explicit', name: :untranslated, null: true, owner: Types::ShipmentType, type: String) }

      it { is_expected.to(eq('Explicit')) }
    end
  end
end
