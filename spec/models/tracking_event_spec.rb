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

    it { expect(record.country).to(equal(Grid::ORM::Country.find('US'))) }
  end

  describe '#discussable_topic_description' do
    subject { record.discussable_topic_description }

    let(:record) { build(:tracking_event, city: 'Fremont') }

    before do
      allow(record.event).to(receive(:active_shipping_code).and_return('departed'))
      allow(I18n).to(receive(:t).and_call_original)
    end

    it { is_expected.to(include(Shipment.model_name.human, 'Fremont')) }
    it { is_expected.not_to(include('Translation missing')) }

    context 'with the translation arguments' do
      before { record.discussable_topic_description }

      it do
        expect(I18n)
          .to(
            have_received(:t)
              .with(
                'discussion_topics.tracking_event.departed',
                city: 'Fremont',
                country_alpha2: 'US',
                model_name: Shipment.model_name.human,
                region_abbreviation: 'CA'
              )
          )
      end
    end
  end

  describe '#region' do
    let(:record) { build(:tracking_event) }

    it { expect(record.region).to(equal(Grid::ORM::Region.find('US-CA'))) }
  end
end
