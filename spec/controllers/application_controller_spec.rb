require 'rails_helper'

RSpec.describe(ApplicationController) do
  controller do
    def index = (render(plain: 'OK') if stale?(*objects, **options))
    def objects = []
    def options = {}
  end

  let(:item) { create(:item, shipment:, updated_at: 2.days.ago) }
  let(:shipment) { create(:shipment, updated_at: 3.days.ago) }

  describe '#last_modified_of' do
    subject(:last_modified) { controller.__send__(:last_modified_of, object) }

    context 'with a record' do
      let(:object) { shipment }

      it { is_expected.to(eq(shipment.updated_at)) }
    end

    context 'with a relation' do
      let(:object) { Item.where(shipment:) }

      before { item }

      it { is_expected.to(eq(item.reload.updated_at)) }
      it { expect { last_modified }.not_to(change(object, :loaded?)) }
    end

    context 'with an array' do
      let(:object) { [shipment, item, nil] }

      it { is_expected.to(eq(item.updated_at)) }
    end

    context 'with an empty relation' do
      let(:object) { Item.none }

      it { is_expected.to(be_nil) }
    end

    context 'without updated_at' do
      let(:object) { 'string' }

      it { is_expected.to(be_nil) }
    end
  end

  describe '#stale?' do
    let(:objects) { [shipment, Item.where(shipment:), nil] }
    let(:options) { {} }

    before do
      item
      allow(controller).to(receive_messages(objects:, options:))
    end

    context 'with a matching etag' do
      before do
        get :index
        request.headers['If-None-Match'] = response.etag
        get :index
      end

      it { is_expected.to(have_http_status(:not_modified)) }
    end

    context 'with a relation' do
      before { get :index }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(objects.second).not_to(be_loaded) }
      it { expect(response.etag).to(be_present) }
      it { expect(response.last_modified).to(be_within(1.second).of(item.updated_at)) }
    end

    context 'with a relation member changed after the first request' do
      let(:first_etag) do
        get :index
        response.etag
      end

      before do
        allow(controller).to(receive(:objects) { [shipment, Item.where(shipment:)] })
        request.headers['If-None-Match'] = first_etag
        item.update!(desc: 'Changed')
        get :index
      end

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.etag).not_to(eq(first_etag)) }
    end

    context 'with an array of records' do
      let(:objects) { [[shipment, item]] }

      context 'when in production' do
        before do
          allow(Rails).to(receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('production')))
          allow(ActiveSupport.deprecator).to(receive(:warn))
          get :index
        end

        it { is_expected.to(have_http_status(:ok)) }
        it { expect(ActiveSupport.deprecator).to(have_received(:warn).with(/Passing an array to `stale\?`/, anything)) }
      end

      context 'when not in production' do
        it { expect { get :index }.to(raise_error(RuntimeError, /Passing an array to `stale\?`/)) }
      end
    end

    context 'with explicit options' do
      let(:last_modified) { 1.hour.ago.change(usec: 0) }
      let(:options) { { etag: 'custom', last_modified: } }

      before { get :index }

      it { expect(response.last_modified).to(eq(last_modified)) }
    end
  end
end
