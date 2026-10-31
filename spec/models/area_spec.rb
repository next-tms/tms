# == Schema Information
#
# Table name: areas
#
# @!attribute id
#   @return []
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_areas_on_name  (name)
#
require 'rails_helper'

RSpec.describe(Area) do
  describe '.find_or_create_by_region!' do
    subject(:area) { described_class.find_or_create_by_region!(texas) }

    let(:texas) { Transponder::ORM::Region.find('US-TX') }

    it { expect { area }.to(change(described_class, :count).by(1)) }
    it { expect(area.name).to(eq('Texas, US')) }
    it { expect(area.locations.map { |location| [location.region_iso31662, location.zip_code] }).to(eq([['US-TX', nil]])) }

    context 'when the region area exists' do
      let!(:existing) { described_class.find_or_create_by_region!(texas) }

      it { expect(area).to(eq(existing)) }
      it { expect { area }.not_to(change(described_class, :count)) }
    end

    context 'when only an area with several whole regions includes the region' do
      before do
        described_class.create!(locations: [Location.new(region: texas), Location.new(region_iso31662: 'US-CA')], name: 'Southwest, US')
      end

      it { expect { area }.to(change(described_class, :count).by(1)) }
      it { expect(area.name).to(eq('Texas, US')) }
    end

    context 'when only a ZIP code area includes the region' do
      before { described_class.create!(locations: [Location.new(region: texas, zip_code: '78701')], name: 'Austin Metro, US') }

      it { expect { area }.to(change(described_class, :count).by(1)) }
    end
  end

  describe 'relationships' do
    it { is_expected.to(have_many(:location_areas).dependent(:destroy)) }
  end
end
