# frozen_string_literal: true

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

RSpec.describe(Discussion, type: :model) do
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
end
