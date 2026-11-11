require 'rails_helper'

RSpec.describe(Setting) do
  describe '.configuration' do
    it { expect(described_class.configuration).to(include({ key: 'copyright_holder', kind: :string })) }
    it { expect(described_class.configuration).to(be_frozen) }
  end

  describe '.keys' do
    it { expect(described_class.keys).to(include('copyright_holder', 'customer_service_email')) }
  end

  describe '.method_missing' do
    context 'when key is configured' do
      before { create(:setting, key: 'phone', value: '+15035550100') }

      it { expect(described_class.phone).to(eq('+15035550100')) }
    end

    context 'when key is configured and method ends with !' do
      before { create(:setting, key: 'phone', value: '+15035550100') }

      it { expect(described_class.phone!).to(eq('+15035550100')) }
    end

    context 'when key is missing' do
      it { expect(described_class.robot_email).to(be_nil) }
    end

    context 'when key is missing and method ends with !' do
      it { expect { described_class.robot_email! }.to(raise_error(ActiveRecord::RecordNotFound)) }
    end

    context 'when key is not configured' do
      it { expect { described_class.not_a_setting }.to(raise_error(NoMethodError)) }
    end

    context 'when key is missing and a fallback is passed' do
      it { expect(described_class.phone('+15035550199')).to(eq('+15035550199')) }
    end

    context 'when a fallback is passed and method ends with !' do
      it { expect { described_class.phone!('+15035550199') }.to(raise_error(ArgumentError)) }
    end
  end

  describe '.required_keys' do
    it { expect(described_class.required_keys).to(include('mailing_address')) }
  end

  describe '.respond_to_missing?' do
    it { expect(described_class).to(respond_to(:mailing_address)) }
    it { expect(described_class).to(respond_to(:mailing_address!)) }
    it { expect(described_class).not_to(respond_to(:not_a_setting)) }
  end

  describe '.time_zone' do
    subject(:time_zone) { described_class.time_zone }

    before { create(:setting, key: 'time_zone_name', value: 'America/Chicago') }

    it { is_expected.to(eq(ActiveSupport::TimeZone.new('America/Chicago'))) }
  end

  describe '.value!' do
    context 'when kind == :address' do
      subject(:value) { described_class.value!(:mailing_address) }

      let(:address) { create(:address) }

      before { create(:setting, key: 'mailing_address', value: address.id.to_s) }

      it { is_expected.to(eq(address)) }
    end
  end

  describe '#address' do
    subject(:address) { record.address }

    let(:company_address) { create(:address) }
    let(:record) { build(:setting, key: 'mailing_address', value: company_address.id.to_s) }

    it { is_expected.to(eq(company_address)) }

    context 'when value does not point to an address' do
      let(:record) { build(:setting, key: 'mailing_address', value: '0') }

      it { is_expected.to(be_a_new(Address)) }
    end

    context 'when value is blank' do
      let(:record) { build(:setting, key: 'mailing_address', value: '') }

      it { is_expected.to(be_a_new(Address)) }
      it { expect(record).not_to(be_valid) }
    end

    context 'when not address?' do
      let(:record) { build(:setting, key: 'name') }

      it { is_expected.to(be_nil) }
    end
  end

  describe '#address?' do
    it { expect(build(:setting, key: 'mailing_address')).to(be_address) }
    it { expect(build(:setting, key: 'name')).not_to(be_address) }
  end

  describe '#address_attributes=' do
    let(:record) { build(:setting, key: 'mailing_address', value: nil) }

    before do
      record.address_attributes = {
        city: 'Portland',
        country_alpha2: 'US',
        region_iso31662: 'US-CA',
        street: '123 Main St',
        zip_code: '97201'
      }
    end

    it { expect(record.address).to(have_attributes(city: 'Portland', region_iso31662: 'US-CA', street: '123 Main St', zip_code: '97201')) }

    context 'when saved' do
      before { record.save! }

      it { expect(record.address).to(be_persisted) }
      it { expect(described_class.find(record.id).value).to(eq(record.address)) }
    end

    context 'when not address?' do
      let(:record) { build(:setting, key: 'name') }

      it { expect(record.address).to(be_nil) }
    end
  end

  describe '#value' do
    context 'when kind == :address' do
      subject(:value) { build(:setting, key: 'mailing_address', value: address.id.to_s).value }

      let(:address) { create(:address) }

      it { is_expected.to(eq(address)) }
    end
  end

  describe '#value=' do
    context 'when new_value.is_a?(Address)' do
      let(:address) { create(:address) }
      let(:record) { build(:setting, key: 'mailing_address', value: address) }

      it { expect(record[:value]).to(eq(address.id.to_s)) }
      it { expect(record.value).to(eq(address)) }
    end
  end

  describe '#kind' do
    subject(:kind) { build(:setting, key: 'time_zone_name').kind }

    it { is_expected.to(eq(:time_zone)) }
  end

  describe '#validate_value' do
    context 'when kind == :address' do
      let(:record) { build(:setting, key: 'mailing_address', value: create(:address).id.to_s) }

      it { expect(record).to(be_valid) }

      context 'when address is changed and invalid' do
        before do
          record.address_attributes = { city: '' }
          record.valid?
        end

        it { expect(record.errors.to_hash.keys).to(include(:address)) }
      end

      context 'when address is missing' do
        let(:record) { build(:setting, key: 'mailing_address', value: '0') }

        before { record.valid? }

        it { expect(record.errors.to_hash.keys).to(include(:address)) }
      end
    end

    context 'when kind == :boolean' do
      before { allow(record).to(receive(:kind).and_return(:boolean)) }

      let(:record) { build(:setting, value: Faker::Boolean.boolean) }

      it { expect(record).to(be_valid) }

      context 'when not value.is_a?(TrueClass) || value.is_a?(FalseClass)' do
        let(:record) { build(:setting, value: Faker::Alphanumeric.alpha) }

        before { record.valid? }

        it { expect(record).not_to(be_valid) }
        it { expect(record.errors.to_hash.keys).to(include(:value)) }
      end
    end

    context 'when kind == :email' do
      before { allow(record).to(receive(:kind).and_return(:email)) }

      let(:record) { build(:setting, value: Faker::Internet.email) }

      it { expect(record).to(be_valid) }

      context 'when not value =~ URI::MailTo::EMAIL_REGEXP' do
        let(:record) { build(:setting, value: Faker::Alphanumeric.alpha) }

        before { record.valid? }

        it { expect(record).not_to(be_valid) }
        it { expect(record.errors.to_hash.keys).to(include(:value)) }
      end
    end

    context 'when kind == :hostname' do
      before { allow(record).to(receive(:kind).and_return(:hostname)) }

      let(:record) { build(:setting, value: Faker::Internet.domain_name(subdomain: [true, false].sample)) }

      it { expect(record).to(be_valid) }

      context 'when not value =~ DOMAIN_REGEX' do
        let(:record) { build(:setting, value: Faker::Alphanumeric.alpha) }

        before { record.valid? }

        it { expect(record).not_to(be_valid) }
        it { expect(record.errors.to_hash.keys).to(include(:value)) }
      end
    end

    context 'when kind == :integer' do
      before { allow(record).to(receive(:kind).and_return(:integer)) }

      let(:record) { build(:setting, value: '5000') }

      it { expect(record).to(be_valid) }

      context 'when not value.to_i.to_s == value && value.to_i.positive?' do
        let(:record) { build(:setting, value: Faker::Alphanumeric.alpha) }

        before { record.valid? }

        it { expect(record).not_to(be_valid) }
        it { expect(record.errors.to_hash.keys).to(include(:value)) }
      end
    end

    context 'when kind == :uri' do
      before { allow(record).to(receive(:kind).and_return(:uri)) }

      let(:record) { build(:setting, value: Faker::Internet.url) }

      it { expect(record).to(be_valid) }

      context 'when not URI.parse(value) && [uri.scheme, uri.host].all?(&:present?)' do
        let(:record) { build(:setting, value: Faker::Alphanumeric.alpha) }

        before { record.valid? }

        it { expect(record).not_to(be_valid) }
        it { expect(record.errors.to_hash.keys).to(include(:value)) }
      end
    end

    context 'when kind == :time_zone' do
      before { allow(record).to(receive(:kind).and_return(:time_zone)) }

      let(:record) { build(:setting, value: ActiveSupport::TimeZone.all.map(&:tzinfo).sample.name) }

      it { expect(record).to(be_valid) }

      context 'when not URI.parse(value) && [uri.scheme, uri.host].all?(&:present?)' do
        let(:record) { build(:setting, value: Faker::Alphanumeric.alpha) }

        before { record.valid? }

        it { expect(record).not_to(be_valid) }
        it { expect(record.errors.to_hash.keys).to(include(:value)) }
      end
    end
  end

  describe 'db/seed/settings.yaml' do
    let(:entries) { YAML.safe_load_file(Rails.root.join('db/seed/settings.yaml')).fetch('settings') }

    it { expect(entries.map { |entry| described_class.new(entry) }).to(all(be_valid)) }
    it { expect(entries.pluck('key')).to(include('theme_primary_color', 'theme_sidebar_background_color', 'theme_sidebar_text_color')) }
  end

  describe '.instigators' do
    let!(:instigator) { create(:setting, key: 'requires_charges_confirmed_on_receivables', value: true) }

    before { create(:setting, key: 'phone', value: '+15035550100') }

    it { expect(described_class.instigators).to(contain_exactly(instigator)) }
  end

  describe '#name' do
    let(:record) { build(:setting, key: 'requires_charges_confirmed_on_receivables', value: true) }

    before { create(:setting, key: 'name', value: 'Acme Freight') }

    it { expect(record.name).to(eq('Acme Freight')) }
  end

  describe '#requires_charges_confirmed_on_receivables?' do
    subject { build(:setting, key: 'requires_charges_confirmed_on_receivables', value:) }

    context 'when the value is true' do
      let(:value) { true }

      it { is_expected.to(be_requires_charges_confirmed_on_receivables) }
    end

    context 'when the value is false' do
      let(:value) { false }

      it { is_expected.not_to(be_requires_charges_confirmed_on_receivables) }
    end
  end

  describe '#shipments' do
    let!(:shipment) { create(:shipment) }

    it { expect(build(:setting).shipments).to(include(shipment)) }
  end

  describe '#suppressor_mappings' do
    it do
      setting = build(:setting, key: 'requires_charges_confirmed_on_receivables')

      expect(setting.__send__(:suppressor_mappings).keys).to(eq(%i[requires_charges_confirmed_on_receivables]))
    end

    it { expect(build(:setting, key: 'phone').__send__(:suppressor_mappings)).to(be_empty) }
  end

  describe '#update_suppressors' do
    let(:record) { create(:setting, key: 'requires_charges_confirmed_on_receivables', value: true) }

    it { expect(record.suppressors.pluck(:problematic_rule_code)).to(eq(['missing_charges_confirmed'])) }

    context 'when value changes to false' do
      before { record.update!(value: false) }

      it { expect(record.suppressors.reload).to(be_empty) }
    end
  end

  describe '#update_broker_carriers_ignore_bol_requires_tracking_number' do
    let!(:broker_carrier) { create(:broker_carrier, ignore_bol_requires_tracking_number: false) }

    before { create(:setting, key: 'ignore_broker_carrier_bol_requires_tracking_number', value: true) }

    it { expect(broker_carrier.reload.ignore_bol_requires_tracking_number).to(be(true)) }

    context 'when another setting changes' do
      before do
        broker_carrier.reload.update!(ignore_bol_requires_tracking_number: false)
        create(:setting, key: 'phone', value: '+15035550100')
      end

      it { expect(broker_carrier.reload.ignore_bol_requires_tracking_number).to(be(false)) }
    end
  end
end
