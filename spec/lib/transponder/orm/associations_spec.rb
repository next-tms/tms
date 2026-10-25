require 'rails_helper'

RSpec.describe(Transponder::ORM::Associations) do
  let(:model_class) do
    Class.new(ApplicationRecord) do
      self.table_name = 'addresses'

      def self.name = 'AssociationsTestRecord'

      belongs_to_transponder :country, foreign_key: :country_alpha2
      belongs_to_transponder :region, foreign_key: :region_iso31662, optional: true
    end
  end

  let(:record) { model_class.new(country_alpha2:, region_iso31662:) }
  let(:country_alpha2) { 'US' }
  let(:region_iso31662) { 'US-CA' }

  describe 'reader' do
    it { expect(record.country).to(equal(Transponder::ORM::Country.find('US'))) }
    it { expect(record.region).to(equal(Transponder::ORM::Region.find('US-CA'))) }

    context 'when the code is blank' do
      let(:region_iso31662) { nil }

      it { expect(record.region).to(be_nil) }
    end

    context 'when Transponder no longer returns the code' do
      let(:region_iso31662) { 'US-ZZ' }

      it { expect(record.region.abbreviation).to(eq('ZZ')) }
    end
  end

  describe 'writer' do
    it { expect { record.region = Transponder::ORM::Region.find('US-TX') }.to(change(record, :region_iso31662).to('US-TX')) }
    it { expect { record.region = nil }.to(change(record, :region_iso31662).to(nil)) }
  end

  describe 'validations' do
    before { record.validate }

    it { expect(record.errors).to(be_empty) }

    context 'when a required code is blank' do
      let(:country_alpha2) { nil }

      it { expect(record.errors.of_kind?(:country_alpha2, :blank)).to(be(true)) }
    end

    context 'when an optional code is blank' do
      let(:region_iso31662) { nil }

      it { expect(record.errors).to(be_empty) }
    end

    context 'when a changed code is unknown' do
      let(:region_iso31662) { 'US-ZZ' }

      it { expect(record.errors.of_kind?(:region, :invalid)).to(be(true)) }
    end

    context 'when an unchanged code is unknown' do
      let(:record) do
        model_class.new(country_alpha2:, region_iso31662: 'US-ZZ').tap { |record| record.clear_changes_information }
      end

      it { expect(record.errors).to(be_empty) }
    end
  end
end
