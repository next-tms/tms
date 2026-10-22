require 'rails_helper'

RSpec.describe(DateTimeHelper) do
  describe('#flatpickr_data') do
    subject(:result) { helper.flatpickr_data(options) }

    let(:options) { {} }

    it { is_expected.to(eq(controller: 'flatpickr', flatpickr_date_format: 'Y-m-d')) }

    context 'when options' do
      let(:options) { { flatpickr_max_date: Date.new(2024, 2, 14) } }

      it do
        expect(result).to(
          eq(controller: 'flatpickr', flatpickr_date_format: 'Y-m-d', flatpickr_max_date: Date.new(2024, 2, 14)),
        )
      end
    end

    context 'when options[:override].present?' do
      let(:options) { { override: { flatpickr_date_format: 'h:i K', flatpickr_enable_time: true } } }

      it { is_expected.to(eq(controller: 'flatpickr', flatpickr_date_format: 'h:i K', flatpickr_enable_time: true)) }
    end
  end

  describe('#hours_range') do
    subject { helper.hours_range(date, start_at, end_at, time_zone) }

    let(:date) { Date.new(2024, 3, 10) }
    let(:end_at) { '05:00 PM' }
    let(:start_at) { '09:00 AM' }
    let(:time_zone) { ActiveSupport::TimeZone['America/Los_Angeles'] }

    it { is_expected.to(eq('09:00 AM - 05:00 PM <small>PDT</small>')) }
    it { is_expected.to(be_html_safe) }

    context 'when date.blank?' do
      let(:date) { nil }

      it { is_expected.to(eq('09:00 AM - 05:00 PM')) }
    end

    context 'when end_at.blank?' do
      let(:end_at) { nil }

      it { is_expected.to(be_nil) }
    end

    context 'when hours are not parseable' do
      let(:start_at) { 'morning' }

      it { is_expected.to(eq('morning - 05:00 PM')) }
    end

    context 'when hours contain HTML' do
      let(:start_at) { '<b>9</b>' }

      it { is_expected.to(eq('&lt;b&gt;9&lt;/b&gt; - 05:00 PM')) }
    end

    context 'when range spans a daylight saving transition' do
      let(:end_at) { '05:00 AM' }
      let(:start_at) { '01:00 AM' }

      it { is_expected.to(eq('01:00 AM <small>PST</small> - 05:00 AM <small>PDT</small>')) }
    end

    context 'when start_at.blank?' do
      let(:start_at) { nil }

      it { is_expected.to(be_nil) }
    end

    context 'when time_zone.blank?' do
      let(:time_zone) { nil }

      it { is_expected.to(eq('09:00 AM - 05:00 PM')) }
    end
  end

  describe('#pretty_date') do
    subject { helper.pretty_date(date, time_zone, abbreviation:) }

    let(:abbreviation) { true }
    let(:date) { Time.zone.local(2024, 2, 14, 12, 30) }
    let(:time_zone) { ActiveSupport::TimeZone['America/Los_Angeles'] }

    it { is_expected.to(eq('02/14/24 Wed 4:30 AM <small>PST</small>')) }
    it { is_expected.to(be_html_safe) }

    context 'when date.blank?' do
      let(:date) { nil }

      it { is_expected.to(be_nil) }
    end

    context 'when date is in the current year' do
      around { |example| Timecop.freeze(Time.zone.local(2024, 3, 1)) { example.run } }

      it { is_expected.to(eq('02/14 Wed 4:30 AM <small>PST</small>')) }
    end

    context 'when date is during daylight saving time' do
      let(:date) { Time.zone.local(2024, 7, 14, 12, 30) }

      it { is_expected.to(eq('07/14/24 Sun 5:30 AM <small>PDT</small>')) }
    end

    context 'when time_zone.blank?' do
      let(:time_zone) { nil }

      it { is_expected.to(be_nil) }
    end

    context 'when not abbreviation' do
      let(:abbreviation) { false }

      it { is_expected.to(eq('02/14/24 Wed 4:30 AM')) }
    end
  end

  describe('#time_zone_abbreviation') do
    subject(:result) { helper.time_zone_abbreviation(time_zone, at:) }

    let(:at) { Time.zone.local(2024, 2, 14, 12, 30) }
    let(:time_zone) { ActiveSupport::TimeZone['America/Los_Angeles'] }

    it { is_expected.to(eq('PST')) }

    context 'when at is a Date' do
      let(:at) { Date.new(2024, 7, 14) }

      it { is_expected.to(eq('PDT')) }
    end

    context 'when at is a Date ahead of the server time zone' do
      let(:at) { Date.new(2024, 4, 7) }
      let(:time_zone) { ActiveSupport::TimeZone['Australia/Sydney'] }

      it { is_expected.to(eq('AEDT')) }
    end

    context 'when at is during daylight saving time' do
      let(:at) { Time.zone.local(2024, 7, 14, 12, 30) }

      it { is_expected.to(eq('PDT')) }
    end

    context 'when not time_zone.is_a?(ActiveSupport::TimeZone)' do
      let(:time_zone) { 'PDT' }

      it { expect { result }.to(raise_error(ArgumentError)) }
    end
  end
end
