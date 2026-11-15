require 'rails_helper'

RSpec.describe(Resolvers::Collection) do
  subject(:collection) { described_class.new(Carrier.all, page:, page_size: 2) }

  let!(:carriers) { create_list(:carrier, 3) }
  let(:page) { 1 }

  describe '#items' do
    it { expect(collection.items).to(eq(carriers.first(2))) }

    it do
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') { |*, payload| queries << payload[:sql] }
      collection.items.to_a
      ActiveSupport::Notifications.unsubscribe(subscriber)

      expect(queries.grep(/COUNT/)).to(be_empty)
    end

    context 'with a later page' do
      let(:page) { 2 }

      it { expect(collection.items).to(eq([carriers.last])) }
    end

    context 'with a page past the last page' do
      let(:page) { 3 }

      it { expect { collection.items }.to(raise_error(Pagy::RangeError)) }
    end
  end

  describe '#pages' do
    it { expect(collection.pages).to(eq(2)) }
  end

  describe '#total_items' do
    it { expect(collection.total_items).to(eq(3)) }
  end

  describe '#updated_at' do
    it { expect(collection.updated_at).to(be_within(1.second).of(carriers.map(&:updated_at).max)) }
  end

  describe '#version' do
    it { expect(collection.version).to(eq(Carrier.all.cache_version)) }
  end
end
