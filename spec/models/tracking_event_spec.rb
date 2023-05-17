# frozen_string_literal: true

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
# @!attribute interstellar_carrier_fingerprint
#   @return [String]
# @!attribute public
#   @return [Boolean]
# @!attribute time_zone_name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute address_id
#   @return []
# @!attribute country_id
#   @return []
# @!attribute event_id
#   @return []
# @!attribute region_id
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
#  index_tracking_events_on_address_id   (address_id)
#  index_tracking_events_on_country_id   (country_id)
#  index_tracking_events_on_event_id     (event_id)
#  index_tracking_events_on_region_id    (region_id)
#  index_tracking_events_on_shipment_id  (shipment_id)
#  index_tracking_events_on_terminal_id  (terminal_id)
#  index_tracking_events_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (country_id => countries.id)
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (region_id => regions.id)
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (terminal_id => terminals.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe(TrackingEvent, type: :model) do
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
end
