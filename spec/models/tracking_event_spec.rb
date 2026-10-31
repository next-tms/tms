# == Schema Information
#
# Table name: tracking_events
#
# @!attribute id
#   @return []
# @!attribute api_request
#   @return [String]
# @!attribute api_response
#   @return [String]
# @!attribute at
#   @return [Time]
# @!attribute city
#   @return [String]
# @!attribute country_alpha2
#   @return [String]
# @!attribute freight_kit_carrier_fingerprint
#   @return [String]
# @!attribute public
#   @return [Boolean]
# @!attribute region_iso31662
#   @return [String]
# @!attribute time_zone_name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute address_id
#   @return []
# @!attribute event_id
#   @return []
# @!attribute shipment_id
#   @return []
# @!attribute terminal_id
#   @return []
# @!attribute user_id
#   @return []
#
# Indexes
#
#  index_tracking_events_on_address_id       (address_id)
#  index_tracking_events_on_country_alpha2   (country_alpha2)
#  index_tracking_events_on_event_id         (event_id)
#  index_tracking_events_on_region_iso31662  (region_iso31662)
#  index_tracking_events_on_shipment_id      (shipment_id)
#  index_tracking_events_on_terminal_id      (terminal_id)
#  index_tracking_events_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (terminal_id => terminals.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe(TrackingEvent) do
  it_behaves_like 'discussable_topic'

  describe '#build_discussable_topic?' do
    let(:record) { build(:tracking_event) }

    context 'when Event#active_shipping_code included in TrackingEvent::DISCUSSABLE_EVENT_ACTIVE_SHIPPING_CODES' do
      before do
        included_active_shipping_code = TrackingEvent::DISCUSSABLE_EVENT_ACTIVE_SHIPPING_CODES.sample.to_s
        allow(record.event).to(receive(:active_shipping_code).and_return(included_active_shipping_code))
      end

      it { expect(record).to(be_build_discussable_topic) }
    end

    context 'when Event#active_shipping_code not included in TrackingEvent::DISCUSSABLE_EVENT_ACTIVE_SHIPPING_CODES' do
      it { is_expected.not_to(be_build_discussable_topic) }
    end
  end

  describe '#country' do
    let(:record) { build(:tracking_event) }

    it { expect(record.country).to(equal(Transponder::ORM::Country.find('US'))) }
  end

  describe '#discussable_topic_description' do
    let(:record) { build(:tracking_event, city: 'Fremont') }

    before do
      allow(record.event).to(receive(:active_shipping_code).and_return('departed'))
      allow(I18n).to(receive(:t).and_call_original)

      record.discussable_topic_description
    end

    it do
      expect(I18n)
        .to(have_received(:t).with('discussion_topics.tracking_event.departed', city: 'Fremont', country_alpha2: 'US',
                                                                                region_abbreviation: 'CA'))
    end
  end

  describe '#region' do
    let(:record) { build(:tracking_event) }

    it { expect(record.region).to(equal(Transponder::ORM::Region.find('US-CA'))) }
  end
end
