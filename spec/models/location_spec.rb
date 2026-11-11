require 'rails_helper'

RSpec.describe(Location) do
  let(:location) { described_class.new(region_iso31662:) }
  let(:region_iso31662) { 'US-TX' }

  describe '#region' do
    it { expect(location.region).to(equal(Transponder::ORM::Region.find('US-TX'))) }
  end

  describe 'relationships' do
    it { is_expected.to(have_many(:location_areas).dependent(:destroy)) }
  end

  describe 'validations' do
    before { location.validate }

    it { expect(location.errors).to(be_empty) }

    context 'when the region is blank' do
      let(:region_iso31662) { nil }

      it { expect(location.errors.of_kind?(:region_iso31662, :blank)).to(be(true)) }
    end
  end
end
