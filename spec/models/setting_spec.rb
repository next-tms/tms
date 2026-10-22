# == Schema Information
#
# Table name: settings
#
# @!attribute id
#   @return []
# @!attribute key
#   @return [String]
# @!attribute value
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_settings_on_key  (key)
#
require 'rails_helper'

RSpec.describe(Setting) do
  describe '.time_zone' do
    subject(:time_zone) { described_class.time_zone }

    before { create(:setting, key: 'time_zone_name', value: 'America/Chicago') }

    it { is_expected.to(eq(ActiveSupport::TimeZone.new('America/Chicago'))) }
  end

  describe '#kind' do
    subject(:kind) { build(:setting, key: 'time_zone_name').kind }

    it { is_expected.to(eq(:time_zone)) }
  end

  describe '#validate_value' do
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

      let(:record) { build(:setting, value: Faker::Internet.domain_name(subdomain: [ true, false ].sample)) }

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
end
