require 'rails_helper'

RSpec.describe(ShipmentsHelper) do
  describe '#accessorial_options' do
    subject(:options) { helper.accessorial_options(nil) }

    let!(:accessorial) { create(:accessorial, name: 'Lift gate', transponder_code: 'liftgate_delivery') }

    it { is_expected.to(include(['Lift gate', accessorial.id.to_s], ['Residential Delivery', 'residential_delivery'])) }
    it { expect(options.map(&:last)).not_to(include('liftgate_delivery')) }

    context 'when called again' do
      before do
        options
        allow(Accessorial).to(receive(:eligible))
      end

      it { expect(helper.accessorial_options(nil)).to(eq(options)) }
    end
  end

  describe '#charges_confirmed_note' do
    subject(:note) { helper.charges_confirmed_note(shipment) }

    let(:shipment) { create(:shipment, charges_confirmed: false) }
    let(:user) { create(:broker_user, first_name: '<b>Jane</b>', last_name: 'Doe') }

    before do
      allow(helper).to(receive(:current_user))
      create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles')

      Timecop.freeze(Time.utc(2026, 7, 14, 17)) { Audited.audit_class.as_user(user) { shipment.update!(charges_confirmed: true) } }
    end

    it { is_expected.to(start_with('Shipment Charges Confirmed by &lt;b&gt;Jane&lt;/b&gt; Doe at <time ')) }
    it { is_expected.to(include('datetime="2026-07-14T10:00:00-07:00" data-controller="time"')) }
  end

  describe '#website_homepage_host' do
    subject { helper.website_homepage_host }

    it { is_expected.to(be_nil) }

    context 'when website_homepage is set' do
      before { create(:setting, key: 'website_homepage', value: 'https://example.com/about') }

      it { is_expected.to(eq('example.com')) }
    end
  end
end
